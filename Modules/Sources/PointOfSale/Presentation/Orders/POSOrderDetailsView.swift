import SwiftUI
import Shimmer
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSRefundItem
import enum Yosemite.OrderStatusEnum
import typealias Yosemite.OrderItemAttribute

struct POSOrderDetailsView: View {
    let order: POSOrder
    let onBack: () -> Void
    var flow: Flow = .orders
    @State var autoStartNextRefundFlow: Bool = false
    var onRefundSuccess: (() -> Void)? = nil
    var onRefundFailure: ((Error) -> Void)? = nil

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.siteTimezone) private var siteTimezone
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @State private var isShowingEmailReceiptView = false
    @State private var refundModalState: RefundModalState?

    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
    }

    private var shouldShowDedicatedRefundsSection: Bool {
        featureFlags.isFeatureFlagEnabled(.pointOfSaleRefundsi1)
    }

    private var dateFormatter: DateFormatter {
        DateFormatter.posDateAndTimeFormatter(timeZone: siteTimezone)
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: POSOrderListView.Localization.orderTitle(order.number),
                backButtonConfiguration: shouldShowBackButton ? .init(state: .enabled, action: onBack) : nil,
                trailingContent: {
                    actionsSection(setup: availableActionsSetup)
                },
                bottomContent: {
                    headerBottomContent(for: order)
                }
            )
            .posHeaderBackButtonPadding(POSPadding.none)
            .fixedSize(horizontal: false, vertical: true)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    if !order.lineItems.isEmpty {
                        productsSection(order)
                    }
                    if shouldShowDedicatedRefundsSection && orderListModel.ordersController.isLoadingOrderRefunds {
                        ghostRefundedProductsSection
                    }
                    let refundedItems = order.refunds.flatMap { $0.items }
                    if shouldShowDedicatedRefundsSection
                        && !orderListModel.ordersController.isLoadingOrderRefunds
                        && !refundedItems.isEmpty {
                        refundedProductsSection(refundedItems)
                    }
                    POSTotalsSectionView(
                        sectionTitle: Localization.totalsTitle,
                        subtotalLabel: Localization.productsLabel,
                        subtotalAmount: order.formattedSubtotal,
                        discountAmount: order.formattedDiscountTotal,
                        taxAmount: order.formattedTotalTax,
                        totalAmount: order.formattedTotal,
                        paidAmount: order.formattedPaymentTotal,
                        paymentMethodTitle: order.paymentMethodTitle,
                        refunds: order.refunds,
                        netAmount: order.formattedNetAmount,
                        siteTimezone: siteTimezone,
                        isLoadingRefundDetails: orderListModel.ordersController.isLoadingOrderRefunds
                    )
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
        .posModal(item: $refundModalState, onDismiss: {
            orderListModel.ordersController.clearRefundSelection()
        }) { state in
            POSRefundModalContentView(
                state: state,
                modalState: $refundModalState,
                order: order,
                onRetryLoading: { initiateRefundFlow() },
                onRetryPreparation: {
                    if flow == .bookings {
                        initiateRefundFlow()
                    } else {
                        refundModalState = .itemSelection
                    }
                },
                onEditRefund: flow == .bookings ? nil : { refundModalState = .itemSelection },
                showsItemSelection: flow != .bookings,
                onRefundSuccess: onRefundSuccess,
                onRefundFailure: onRefundFailure,
                errorStrings: .init(
                    loadTitle: Localization.loadRefundErrorTitle,
                    loadSubtitle: Localization.loadRefundErrorSubtitle,
                    prepareTitle: Localization.prepareRefundErrorTitle,
                    prepareSubtitle: Localization.prepareRefundErrorSubtitle,
                    createTitle: Localization.createRefundErrorTitle,
                    createSubtitle: Localization.createRefundErrorSubtitle
                )
            )
        }
        .posFullScreenCover(isPresented: $isShowingEmailReceiptView) {
            POSSendReceiptView(isShowingSendReceiptView: $isShowingEmailReceiptView) { email in
                try await orderListModel.sendReceipt(order: order, email: email)
            }
            .posHeaderBackButtonIcon(systemName: "xmark")
        }
        .task {
            guard shouldShowDedicatedRefundsSection else { return }
            await orderListModel.ordersController.loadOrderRefunds()
        }
        .onAppear {
            if autoStartNextRefundFlow {
                autoStartNextRefundFlow = false
                initiateRefundFlow()
            }
            analytics.track(event: WooAnalyticsEvent.PointOfSale.orderDetailsLoaded(
                orderID: order.id,
                orderStatus: order.status.rawValue,
                orderCreatedDate: order.dateCreated,
                siteTimezone: siteTimezone
            ))
        }
    }
}


private struct POSRefundNothingToRefundError: LocalizedError {
    var errorDescription: String? {
        "Nothing to refund. Order lineItems may be empty."
    }
}

// MARK: - Main Sections

private extension POSOrderDetailsView {
    @ViewBuilder
    func productsSection(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.productsTitle)
                .font(.posBodyXLargeRegular)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.small) {
                ForEach(Array(order.lineItems.enumerated()), id: \.element.itemID) { index, item in
                    productRow(item: item)

                    if index < order.lineItems.count - 1 {
                        divider
                    }
                }
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    var ghostRefundedProductsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.refundedProductsTitle)
                .font(.posBodyXLargeRegular)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            ghostRefundedProductRow
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var ghostRefundedProductRow: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            ghostLine(width: Constants.productImageSize, height: Constants.productImageSize)

            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                ghostLine(width: Constants.longWidth, height: Constants.rowHeight)
                ghostLine(width: Constants.shortWidth, height: Constants.rowHeight)
            }

            Spacer()

            ghostLine(width: Constants.extraShortWidth, height: Constants.rowHeight)
        }
    }

    private func ghostLine(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.posOnSurfaceVariantLowest)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            .shimmering()
    }

    @ViewBuilder
    func refundedProductsSection(_ items: [POSRefundItem]) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.refundedProductsTitle)
                .font(.posBodyXLargeRegular)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.small) {
                ForEach(items) { item in
                    refundedProductRow(item: item)

                    if item.id != items.last?.id {
                        divider
                    }
                }
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

}


// MARK: - Header Components

private extension POSOrderDetailsView {
    @ViewBuilder
    func headerBottomContent(for order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(dateFormatter.string(from: order.dateCreated))
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .fixedSize(horizontal: false, vertical: true)

            if let customerEmail = order.customerEmail, customerEmail.isNotEmpty {
                Text(customerEmail)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer().frame(height: POSSpacing.xSmall)
            POSOrderBadgeView(order: order)
        }
        .padding(.top, POSSpacing.xSmall)
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerBottomContentAccessibilityLabel(for: order))
    }

    private func headerBottomContentAccessibilityLabel(for order: POSOrder) -> String {
        let date = dateFormatter.string(from: order.dateCreated)
        let email = order.customerEmail
        let status = order.status.localizedName

        return Localization.headerBottomContentAccessibilityLabel(
            date: date,
            email: email,
            status: status
        )
    }

}

// MARK: - Product Components

private extension POSOrderDetailsView {
    @ViewBuilder
    func productRow(item: POSOrderItem) -> some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            productImageView(item: item)
            productDetailsView(item: item)
            Spacer()
            productTotalView(item: item)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(productRowAccessibilityLabel(for: item))
    }

    private func productRowAccessibilityLabel(for item: POSOrderItem) -> String {
        let attributesText = item.attributes.isEmpty ? nil : item.attributes.map { "\($0.name): \($0.value)" }.joined(separator: ", ")
        return Localization.productRowAccessibilityLabel(
            name: item.name,
            attributes: attributesText,
            quantity: String(item.quantity.intValue),
            unitPrice: item.formattedPrice,
            total: item.formattedTotal
        )
    }

    @ViewBuilder

    func productImageView(item: POSOrderItem) -> some View {
        POSItemImageView(imageSource: item.imageSrc, imageSize: Constants.productImageSize, scale: 1)
            .frame(width: Constants.productImageSize, height: Constants.productImageSize)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
    }

    @ViewBuilder
    func productDetailsView(item: POSOrderItem) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(item.name)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)

            if !item.attributes.isEmpty {
                productAttributesView(item.attributes)
            }

            Text(Localization.quantityLabel(item.quantity.intValue,
                                            item.formattedPrice))
            .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
    }

    @ViewBuilder
    func productAttributesView(_ attributes: [OrderItemAttribute]) -> some View {
        let attributeText = attributes.map { "\($0.name): \($0.value)" }.joined(separator: ", ")
        Text(attributeText)
            .font(.posBodyMediumRegular())
            .foregroundStyle(Color.posOnSurfaceVariantHighest)
    }

    @ViewBuilder
    func productTotalView(item: POSOrderItem) -> some View {
        Text(item.formattedTotal)
            .font(.posBodyMediumRegular())
            .foregroundStyle(Color.posOnSurface)
    }
}

// MARK: - Refunded Product Components

private extension POSOrderDetailsView {
    @ViewBuilder
    func refundedProductRow(item: POSRefundItem) -> some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            POSItemImageView(imageSource: item.imageSrc, imageSize: Constants.productImageSize, scale: 1)
                .frame(width: Constants.productImageSize, height: Constants.productImageSize)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))

            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(item.name)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .fixedSize(horizontal: false, vertical: true)

                Text(Localization.quantityLabel(item.quantity.intValue,
                                                item.formattedPrice))
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }

            Spacer()

            Text(item.formattedTotal)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(refundedProductRowAccessibilityLabel(for: item))
    }

    private func refundedProductRowAccessibilityLabel(for item: POSRefundItem) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.refundedProductRow.accessibilityLabel",
            value: "%1$@, Quantity: %2$@ at %3$@ each, Refunded %4$@",
            comment: "Accessibility label for refunded product row. " +
            "%1$@ is product name, %2$@ is quantity, %3$@ is unit price, %4$@ is refund total."
        )
        return String(format: format,
                      item.name,
                      String(item.quantity.intValue),
                      item.formattedPrice,
                      item.formattedTotal)
    }
}

// MARK: - Actions
private extension POSOrderDetailsView {
    enum OrderDetailsAction: Identifiable, CaseIterable {
        case issueRefund
        case emailReceipt

        var id: String { title }

        var title: String {
            switch self {
            case .issueRefund:  Localization.issueRefundActionTitle
            case .emailReceipt: Localization.emailReceiptActionTitle
            }
        }

        var accessibilityHint: String {
            switch self {
            case .issueRefund:  Localization.issueRefundAccessibilityHint
            case .emailReceipt: Localization.emailReceiptAccessibilityHint
            }
        }

        var priority: Int {
            switch self {
            case .issueRefund:  100
            case .emailReceipt: 50
            }
        }
    }

    func handler(for action: OrderDetailsAction) -> @MainActor () -> Void {
        switch action {
        case .emailReceipt:
            return {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.orderDetailsEmailReceiptTapped())
                isShowingEmailReceiptView = true
            }
        case .issueRefund:
            return { initiateRefundFlow() }
        }
    }

    struct OrderDetailsActionsSetup {
        let primary: OrderDetailsAction?
        let secondary: [OrderDetailsAction]
    }

    var availableActionsSetup: OrderDetailsActionsSetup {
        let email: OrderDetailsAction = .emailReceipt

        switch order.status {
        case .refunded:
            return .init(primary: email, secondary: [])
        case .completed:
            if flow == .bookings {
                return .init(primary: .issueRefund, secondary: [email])
            }
            guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRefundsi1) else {
                return .init(primary: email, secondary: [])
            }

            switch orderListModel.ordersController.refundActionAvailability {
            case .available:
                return .init(primary: .issueRefund, secondary: [email])

            case .unavailable:
                return .init(primary: email, secondary: [])

            case .unknown:
                return .init(primary: nil, secondary: [email])
            }
        default:
            return .init(primary: nil, secondary: [])
        }
    }

    @ViewBuilder
    func actionsSection(setup: OrderDetailsActionsSetup) -> some View {
        if let primary = setup.primary {
            HStack(spacing: POSSpacing.large) {
                Button(primary.title, action: handler(for: primary))
                    .buttonStyle(POSFilledButtonStyle(size: .extraSmall))
                    .accessibilityHint(primary.accessibilityHint)
            }
        }

        if !setup.secondary.isEmpty {
            Menu {
                ForEach(setup.secondary) { action in
                    Button(action.title, action: handler(for: action))
                        .accessibilityHint(action.accessibilityHint)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.posBodyLargeBold)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .foregroundColor(.posOnSurface)
                    .padding(POSPadding.small)
            }
            .menuIndicator(.hidden)
        }
    }

}

private extension POSOrderDetailsView {
    @ViewBuilder
    var divider: some View {
        Divider()
            .overlay(Color.posOutlineVariant.opacity(0.5))
            .padding(.vertical, POSSpacing.small)
    }
}

// MARK: - Refund Flow Helpers

private extension POSOrderDetailsView {
    func initiateRefundFlow() {
        refundModalState = .loading
        Task { @MainActor in
            let result = await orderListModel.ordersController.startRefundFlow()
            switch result {
            case .hasItemsToRefund:
                if flow == .bookings {
                    navigateToRefundReview()
                } else {
                    refundModalState = .itemSelection
                }
            case .nothingToRefund:
                if flow == .bookings {
                    // Temporary log to track "nothing to refund" case for bookings (flow == .bookings == true)
                    // This can be removed once we're sure it works as expected.
                    // Context: p1772005017449939-slack-C070SJRA8DP
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingRefundFailed(
                        error: POSRefundNothingToRefundError()
                    ))
                }
                refundModalState = .nothingToRefund
            case .failed:
                refundModalState = .loadingError
            }
        }
    }

    func navigateToRefundReview() {
        guard let reviewData = orderListModel.ordersController.preparePOSRefundReviewData() else {
            refundModalState = .preparationError
            return
        }
        refundModalState = .review(reviewData)
    }
}


// MARK: - Constants

private enum Constants {
    static let productImageSize: CGFloat = 56
    static let longWidth: CGFloat = 120
    static let shortWidth: CGFloat = 80
    static let extraShortWidth: CGFloat = 60
    static let rowHeight: CGFloat = 16
}

// MARK: - Localization

private enum Localization {
    static let productsTitle = NSLocalizedString(
        "pos.orderDetailsView.productsTitle",
        value: "Products",
        comment: "Section title for the products list"
    )

    static let refundedProductsTitle = NSLocalizedString(
        "pos.orderDetailsView.refundedProductsTitle",
        value: "Refunded products",
        comment: "Section title for the refunded products list in order details"
    )

    static func quantityLabel(_ quantity: Int, _ unitPrice: String) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.quantityLabel",
            value: "%1$d × %2$@",
            comment: "Product quantity and price label. %1$d is the quantity, %2$@ is the unit price."
        )
        return String(format: format, quantity, unitPrice)
    }

    static let totalsTitle = NSLocalizedString(
        "pos.orderDetailsView.totalsTitle",
        value: "Totals",
        comment: "Section title for the order totals breakdown"
    )

    static let productsLabel = NSLocalizedString(
        "pos.orderDetailsView.productsLabel",
        value: "Products",
        comment: "Label for products subtotal in the totals section"
    )

    static let emailReceiptActionTitle = NSLocalizedString(
        "pos.orderDetailsView.emailReceiptAction.title",
        value: "Email receipt",
        comment: "Label for email receipt action on order details view"
    )

    static let emailReceiptAccessibilityHint = NSLocalizedString(
        "pos.orderDetailsView.emailReceiptAction.accessibilityHint",
        value: "Tap to send order receipt via email",
        comment: "Accessibility hint for email receipt button on order details view"
    )

    static let issueRefundActionTitle = NSLocalizedString(
            "pos.orderDetailsView.issueRefundAction.title",
            value: "Issue refund",
            comment: "Primary action button to start issuing a refund on the order details view"
        )

    static let issueRefundAccessibilityHint = NSLocalizedString(
        "pos.orderDetailsView.issueRefundAction.accessibilityHint",
        value: "Start refund flow for this order",
        comment: "Accessibility hint for issue refund button"
    )

    static let moreActionsA11yLabel = NSLocalizedString(
        "pos.orderDetailsView.moreActions.label",
        value: "More actions",
        comment: "Accessibility label for the overflow actions menu button (three dots)"
    )

    static func headerBottomContentAccessibilityLabel(date: String, email: String?, status: String) -> String {
        let baseFormat = NSLocalizedString(
            "pos.orderDetailsView.headerBottomContent.accessibilityLabel",
            value: "Order date: %1$@, Status: %2$@",
            comment: "Accessibility label for order header bottom content. %1$@ is order date and time, %2$@ is order status."
        )
        var label = String(format: baseFormat, date, status)

        if let email = email, email.isNotEmpty {
            let emailFormat = NSLocalizedString(
                "pos.orderDetailsView.headerBottomContent.accessibilityLabel.email",
                value: "Customer email: %1$@",
                comment: "Email portion of order header accessibility label. %1$@ is customer email address."
            )
            label += ", " + String(format: emailFormat, email)
        }

        return label
    }

    static func productRowAccessibilityLabel(name: String, attributes: String?, quantity: String, unitPrice: String, total: String) -> String {
        var label = name
        if let attributes = attributes {
            label += ", \(attributes)"
        }
        let format = NSLocalizedString(
            "pos.orderDetailsView.productRow.accessibilityLabel",
            value: "Quantity: %1$@ at %2$@ each, Total %3$@",
            comment: "Accessibility label for product row. %1$@ is quantity, %2$@ is unit price, %3$@ is total price."
        )
        label += ", " + String(format: format, quantity, unitPrice, total)
        return label
    }

    // MARK: - Refund Error Messages

    static let createRefundErrorTitle = NSLocalizedString(
        "pos.orderDetailsView.createRefundError.title",
        value: "Failed to create refund",
        comment: "Title shown when a refund creation has failed"
    )

    static let createRefundErrorSubtitle = NSLocalizedString(
        "pos.orderDetailsView.createRefundError.subtitle",
        value: "Please try again.",
        comment: "Subtitle shown when a refund creation has failed"
    )

    static let loadRefundErrorTitle = NSLocalizedString(
        "pos.orderDetailsView.loadRefundError.title",
        value: "Couldn't load refund details",
        comment: "Title shown when loading refund information has failed"
    )

    static let loadRefundErrorSubtitle = NSLocalizedString(
        "pos.orderDetailsView.loadRefundError.subtitle",
        value: "Please try again.",
        comment: "Subtitle shown when loading refund information has failed"
    )

    static let prepareRefundErrorTitle = NSLocalizedString(
        "pos.orderDetailsView.prepareRefundError.title",
        value: "Couldn't prepare refund",
        comment: "Title shown when refund data preparation fails"
    )

    static let prepareRefundErrorSubtitle = NSLocalizedString(
        "pos.orderDetailsView.prepareRefundError.subtitle",
        value: "Please try again.",
        comment: "Subtitle shown when refund data preparation fails"
    )
}

extension POSOrderDetailsView {
    enum Flow {
        case orders
        case bookings
    }
}

#if DEBUG
#Preview("Order Details - Completed") {
    POSOrderDetailsView(
        order: POSPreviewHelpers.makePreviewOrder(),
        onBack: {}
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
}

#Preview("Order Details - Refunded") {
    POSOrderDetailsView(
        order: POSPreviewHelpers.makePreviewOrderWithRefund(),
        onBack: {}
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
}

#Preview("Order Details - Failed") {
    POSOrderDetailsView(
        order: POSPreviewHelpers.makePreviewFailedOrder(),
        onBack: {}
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
}

#Preview("Order Details - Without Email") {
    POSOrderDetailsView(
        order: POSPreviewHelpers.makePreviewOrderWithoutEmail(),
        onBack: {}
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
}

#Preview("Order Details - With Net Payment") {
    POSOrderDetailsView(
        order: POSPreviewHelpers.makePreviewOrderWithNetPayment(),
        onBack: {}
    )
    .environment(POSPreviewHelpers.makePreviewOrdersModel(state: .empty))
}
#endif
