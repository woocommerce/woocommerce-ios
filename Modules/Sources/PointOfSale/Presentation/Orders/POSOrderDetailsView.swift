import CocoaLumberjackSwift
import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund
import enum Yosemite.OrderStatusEnum
import typealias Yosemite.OrderItemAttribute

struct POSOrderDetailsView: View {
    let order: POSOrder
    let onBack: () -> Void
    var autoStartRefund: Bool = false
    var onRefundSuccess: (() -> Void)? = nil

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.siteTimezone) private var siteTimezone
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @State private var isShowingEmailReceiptView: Bool = false
    @State private var refundModalState: RefundModalState?

    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter.dateAndTimeFormatter
        formatter.timeZone = siteTimezone
        return formatter
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
                    totalsSection(order)
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
        .posFullScreenCover(isPresented: $isShowingEmailReceiptView) {
            POSSendReceiptView(isShowingSendReceiptView: $isShowingEmailReceiptView) { email in
                try await orderListModel.sendReceipt(order: order, email: email)
            }
            .posHeaderBackButtonIcon(systemName: "xmark")
        }
        .posModal(item: $refundModalState, onDismiss: {
            orderListModel.ordersController.clearRefundSelection()
        }) { state in
            refundModalContent(for: state)
        }
        .onAppear {
            if autoStartRefund {
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

// MARK: - Main Sections

private extension POSOrderDetailsView {
    @ViewBuilder
    func productsSection(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.productsTitle)
                .font(.posBodyXLargeBold)
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
    func totalsSection(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.totalsTitle)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.small) {
                productsSubtotalRow(order)
                discountTotalRow(order)
                taxTotalRow(order)

                divider
                mainTotalRow(order)

                divider
                paidAmountRow(order)

                if !order.refunds.isEmpty {
                    divider
                    refundsSection(order)
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
        POSItemImageView(imageSource: item.imageSrc, imageSize: 56, scale: 1)
            .frame(width: 56, height: 56)
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

// MARK: - Totals Components

private extension POSOrderDetailsView {
    @ViewBuilder
    func productsSubtotalRow(_ order: POSOrder) -> some View {
        totalsRow(
            title: Localization.productsLabel,
            amount: order.formattedSubtotal,
            accessibilityLabel: Localization.subtotalAccessibilityLabel(order.formattedSubtotal)
        )
    }

    @ViewBuilder
    func discountTotalRow(_ order: POSOrder) -> some View {
        if let formattedDiscountTotal = order.formattedDiscountTotal {
            totalsRow(
                title: Localization.discountTotalLabel,
                amount: formattedDiscountTotal,
                accessibilityLabel: Localization.discountAccessibilityLabel(formattedDiscountTotal)
            )
        }
    }

    @ViewBuilder
    func taxTotalRow(_ order: POSOrder) -> some View {
        totalsRow(
            title: Localization.taxesLabel,
            amount: order.formattedTotalTax,
            accessibilityLabel: Localization.taxAccessibilityLabel(order.formattedTotalTax)
        )
    }

    @ViewBuilder
    func mainTotalRow(_ order: POSOrder) -> some View {
        totalsRow(
            title: Localization.totalLabel,
            amount: order.formattedTotal,
            titleColor: .posOnSurface,
            titleFont: .posBodyLargeBold,
            accessibilityLabel: Localization.totalAccessibilityLabel(order.formattedTotal)
        )
    }

    @ViewBuilder
    func paidAmountRow(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.none) {
            totalsRow(
                title: Localization.paidLabel,
                amount: order.formattedPaymentTotal,
                titleColor: .posOnSurface,
                titleFont: .posBodyLargeBold
            )

            if order.paymentMethodTitle.isNotEmpty {
                Text(order.paymentMethodTitle)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Localization.paidAccessibilityLabel(
                amount: order.formattedPaymentTotal,
                method: order.paymentMethodTitle
            )
        )
    }

    @ViewBuilder
    func refundsSection(_ order: POSOrder) -> some View {
        ForEach(order.refunds.sorted(by: { $0.refundID < $1.refundID }), id: \.refundID) { refund in
            refundRow(refund: refund)
            divider
        }

        if let netAmount = order.formattedNetAmount {
            netPaymentRow(netAmount: netAmount)
        }
    }

    @ViewBuilder
    func refundRow(refund: POSOrderRefund) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            totalsRow(
                title: Localization.refundLabel,
                amount: refund.formattedTotal,
                titleColor: .posOnSurface,
                titleFont: .posBodyLargeBold
            )

            if let reason = refund.reason, !reason.isEmpty {
                Text(Localization.reasonLabel(reason))
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localization.refundAccessibilityLabel(amount: refund.formattedTotal, reason: refund.reason))
    }

    @ViewBuilder
    func netPaymentRow(netAmount: String) -> some View {
        totalsRow(
            title: Localization.netPaymentLabel,
            amount: netAmount,
            titleColor: .posOnSurface,
            titleFont: .posBodyLargeBold,
            accessibilityLabel: Localization.netPaymentAccessibilityLabel(netAmount)
        )
    }

    @ViewBuilder
    func totalsRow(
        title: String,
        amount: String,
        titleColor: Color = .posOnSurfaceVariantHighest,
        titleFont: POSFontStyle = .posBodyMediumRegular(),
        accessibilityLabel: String? = nil
    ) -> some View {
        HStack {
            Text(title)
                .font(titleFont)
                .foregroundStyle(titleColor)
            Spacer()
            Text(amount)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel ?? "\(title) \(amount)")
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
            if autoStartRefund {
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

    func emailReceiptAction() {
        analytics.track(event: WooAnalyticsEvent.PointOfSale.orderDetailsEmailReceiptTapped())
        isShowingEmailReceiptView = true
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
                if autoStartRefund {
                    navigateToRefundReview()
                } else {
                    refundModalState = .itemSelection
                }
            case .nothingToRefund:
                refundModalState = .nothingToRefund
            case .failed:
                refundModalState = .loadingError
            }
        }
    }
}

// MARK: - Refund Modal State

enum RefundModalState: Identifiable, Equatable {
    case loading
    case loadingError
    case preparationError
    case nothingToRefund
    case itemSelection
    case review(POSRefundReviewData)
    case reasonInput(POSRefundReviewData)
    case confirmation(POSRefundReviewData)
    case processing(POSRefundReviewData)
    case success(POSRefundReviewData)
    case error(POSRefundReviewData)

    var id: String {
        switch self {
        case .loading: return "loading"
        case .loadingError: return "loadingError"
        case .preparationError: return "preparationError"
        case .nothingToRefund: return "nothingToRefund"
        case .itemSelection: return "itemSelection"
        case .review: return "review"
        case .reasonInput: return "reasonInput"
        case .confirmation: return "confirmation"
        case .processing: return "processing"
        case .success: return "success"
        case .error: return "error"
        }
    }
}

// MARK: - Refund Modal Content

private extension POSOrderDetailsView {
    @ViewBuilder
    func refundModalContent(for state: RefundModalState) -> some View {
        switch state {
        case .loading:
            POSRefundLoadingView()
        case .loadingError:
            POSRefundErrorView(
                title: Localization.loadRefundErrorTitle,
                subtitle: Localization.loadRefundErrorSubtitle,
                onRetry: { initiateRefundFlow() },
                onCancel: { refundModalState = nil },
                onClose: { refundModalState = nil }
            )
        case .preparationError:
            POSRefundErrorView(
                title: Localization.prepareRefundErrorTitle,
                subtitle: Localization.prepareRefundErrorSubtitle,
                onRetry: {
                    if autoStartRefund {
                        initiateRefundFlow()
                    } else {
                        refundModalState = .itemSelection
                    }
                },
                onCancel: { refundModalState = nil },
                onClose: { refundModalState = nil }
            )
        case .nothingToRefund:
            POSRefundNothingToRefundView(
                onClose: { refundModalState = nil }
            )
        case .itemSelection:
            POSRefundItemsSelectionView(
                onClose: { refundModalState = nil },
                onContinue: { navigateToRefundReview() }
            )
        case .review(let reviewData):
            POSRefundReviewView(
                onClose: { refundModalState = nil },
                itemsCount: reviewData.itemsCount,
                formattedItemsSubtotal: reviewData.formattedItemsSubtotal,
                formattedTax: reviewData.formattedTax,
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                refundReason: reviewData.refundReason,
                onAddReason: {
                    refundModalState = .reasonInput(reviewData)
                },
                onContinue: {
                    refundModalState = .confirmation(reviewData)
                },
                onEditRefund: autoStartRefund ? nil : {
                    refundModalState = .itemSelection
                }
            )
        case .reasonInput(let reviewData):
            POSRefundReasonView(
                initialReason: reviewData.refundReason,
                onSave: { reason in
                    var updatedReviewData = reviewData
                    updatedReviewData.refundReason = reason
                    refundModalState = .review(updatedReviewData)
                },
                onBack: {
                    refundModalState = .review(reviewData)
                },
                onClose: {
                    refundModalState = nil
                }
            )
        case .confirmation(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: false,
                onClose: {
                    refundModalState = nil
                },
                onConfirm: {
                    refundModalState = .processing(reviewData)
                    Task { @MainActor in
                        await processRefund(reviewData: reviewData)
                    }
                },
                onBack: {
                    refundModalState = .review(reviewData)
                }
            )
        case .processing(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: true,
                onClose: {},
                onConfirm: {},
                onBack: {}
            )
        case .success(let reviewData):
            POSRefundSuccessView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                onDone: {
                    refundModalState = nil
                },
                onEmailReceipt: {
                    refundModalState = nil
                    Task { @MainActor in
                        isShowingEmailReceiptView = true
                    }
                },
                onClose: {
                    refundModalState = nil
                }
            )
        case .error(let reviewData):
            POSRefundErrorView(
                title: Localization.createRefundErrorTitle,
                subtitle: Localization.createRefundErrorSubtitle,
                onRetry: {
                    refundModalState = .confirmation(reviewData)
                },
                onCancel: {
                    refundModalState = nil
                },
                onClose: {
                    refundModalState = nil
                }
            )
        }
    }

    func navigateToRefundReview() {
        guard let reviewData = orderListModel.ordersController.preparePOSRefundReviewData() else {
            refundModalState = .preparationError
            return
        }
        refundModalState = .review(reviewData)
    }

    @MainActor
    func processRefund(reviewData: POSRefundReviewData) async {
        do {
            try await orderListModel.ordersController.processRefund(reason: reviewData.refundReason)
            refundModalState = .success(reviewData)
            onRefundSuccess?()
        } catch {
            DDLogError("⛔️ Failed to process refund: \(error)")
            refundModalState = .error(reviewData)
        }
    }
}

// MARK: - Localization

private enum Localization {
    static let productsTitle = NSLocalizedString(
        "pos.orderDetailsView.productsTitle",
        value: "Products",
        comment: "Section title for the products list"
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

    static let discountTotalLabel = NSLocalizedString(
        "pos.orderDetailsView.discountTotalLabel",
        value: "Discount total",
        comment: "Label for discount total in the totals section"
    )

    static let taxesLabel = NSLocalizedString(
        "pos.orderDetailsView.taxesLabel",
        value: "Taxes",
        comment: "Label for taxes in the totals section"
    )

    static let totalLabel = NSLocalizedString(
        "pos.orderDetailsView.totalLabel",
        value: "Total",
        comment: "Label for the order total"
    )

    static let paidLabel = NSLocalizedString(
        "pos.orderDetailsView.paidLabel2",
        value: "Total paid",
        comment: "Label for the paid amount"
    )

    static let refundLabel = NSLocalizedString(
        "pos.orderDetailsView.refundLabel",
        value: "Refunded",
        comment: "Label for a refund entry. %1$lld is the refund ID."
    )

    static func reasonLabel(_ reason: String) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.reasonLabel",
            value: "Reason: %1$@",
            comment: "Label for refund reason. %1$@ is the reason text."
        )
        return String(format: format, reason)
    }

    static let netPaymentLabel = NSLocalizedString(
        "pos.orderDetailsView.netPaymentLabel",
        value: "Net Payment",
        comment: "Label for net payment amount after refunds"
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

    static func subtotalAccessibilityLabel(_ amount: String) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.subtotal.accessibilityLabel",
            value: "Products subtotal: %1$@",
            comment: "Accessibility label for products subtotal. %1$@ is the subtotal amount."
        )
        return String(format: format, amount)
    }

    static func discountAccessibilityLabel(_ amount: String) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.discount.accessibilityLabel",
            value: "Discount total: %1$@",
            comment: "Accessibility label for discount total. %1$@ is the discount amount."
        )
        return String(format: format, amount)
    }

    static func taxAccessibilityLabel(_ amount: String) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.tax.accessibilityLabel",
            value: "Taxes: %1$@",
            comment: "Accessibility label for taxes. %1$@ is the tax amount."
        )
        return String(format: format, amount)
    }

    static func totalAccessibilityLabel(_ amount: String) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.total.accessibilityLabel",
            value: "Order total: %1$@",
            comment: "Accessibility label for order total. %1$@ is the total amount."
        )
        return String(format: format, amount)
    }

    static func paidAccessibilityLabel(amount: String, method: String) -> String {
        let baseFormat = NSLocalizedString(
            "pos.orderDetailsView.paid.accessibilityLabel",
            value: "Total paid: %1$@",
            comment: "Accessibility label for total paid. %1$@ is the paid amount."
        )
        var label = String(format: baseFormat, amount)

        if method.isNotEmpty {
            let methodFormat = NSLocalizedString(
                "pos.orderDetailsView.paid.accessibilityLabel.method",
                value: "Payment method: %1$@",
                comment: "Payment method portion of paid accessibility label. %1$@ is the payment method."
            )
            label += ", " + String(format: methodFormat, method)
        }

        return label
    }

    static func refundAccessibilityLabel(amount: String, reason: String?) -> String {
        let baseFormat = NSLocalizedString(
            "pos.orderDetailsView.refund.accessibilityLabel",
            value: "Refunded: %1$@",
            comment: "Accessibility label for refunded amount. %1$@ is the refund amount."
        )
        var label = String(format: baseFormat, amount)

        if let reason = reason, !reason.isEmpty {
            let reasonFormat = NSLocalizedString(
                "pos.orderDetailsView.refund.accessibilityLabel.reason",
                value: "Reason: %1$@",
                comment: "Reason portion of refund accessibility label. %1$@ is the refund reason."
            )
            label += ", " + String(format: reasonFormat, reason)
        }

        return label
    }

    static func netPaymentAccessibilityLabel(_ amount: String) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.netPayment.accessibilityLabel",
            value: "Net payment: %1$@",
            comment: "Accessibility label for net payment. %1$@ is the net payment amount after refunds."
        )
        return String(format: format, amount)
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
