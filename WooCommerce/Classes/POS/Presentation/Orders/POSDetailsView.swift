import SwiftUI
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund
import enum Yosemite.OrderStatusEnum
import typealias Yosemite.OrderItemAttribute

struct POSOrderDetailsView: View {
    let order: POSOrder
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.siteTimezone) private var siteTimezone
    @Environment(POSOrderListModel.self) private var orderListModel
    @State private var isShowingEmailReceiptView: Bool = false

    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter.dateAndTimeFormatter
        formatter.timeZone = siteTimezone
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.orderTitle(order.number),
                backButtonConfiguration: shouldShowBackButton ? .init(state: .enabled, action: onBack) : nil,
                trailingContent: { PointOfSaleOrderBadgeView(order: order) },
                bottomContent: { headerBottomContent(for: order) }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    if actions.isNotEmpty {
                        actionsSection(actions)
                    }

                    if !order.lineItems.isEmpty {
                        productsSection(order)
                    }
                    totalsSection(order)
                }
                .padding(.horizontal, POSPadding.medium)
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
    }
}

// MARK: - Main Sections

private extension POSOrderDetailsView {
    @ViewBuilder
    func productsSection(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.productsTitle)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.small) {
                ForEach(order.lineItems, id: \.itemID) { item in
                    productRow(item: item)
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
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.medium) {
                productsSubtotalRow(order)
                discountTotalRow(order)
                taxTotalRow(order)

                Divider()
                    .background(Color.posSurfaceDim)

                mainTotalRow(order)
                paidAmountRow(order)
                refundsSection(order)
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
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .fixedSize(horizontal: false, vertical: true)

            if let customerEmail = order.customerEmail, customerEmail.isNotEmpty {
                Text(customerEmail)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(.leading)
    }

}

// MARK: - Product Components

private extension POSOrderDetailsView {
    @ViewBuilder
    func productRow(item: POSOrderItem) -> some View {
        HStack(alignment: .top, spacing: POSSpacing.medium) {
            productImageView(item: item)
            productDetailsView(item: item)
            Spacer()
            productTotalView(item: item)
        }
        .padding(.vertical, POSPadding.small)
    }

    @ViewBuilder

    func productImageView(item: POSOrderItem) -> some View {
        POSItemImageView(imageSource: item.imageSrc, imageSize: 40, scale: 1)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
    }

    @ViewBuilder
    func productDetailsView(item: POSOrderItem) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(item.name)
                .font(.posBodyMediumBold)
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)

            if !item.attributes.isEmpty {
                productAttributesView(item.attributes)
            }

            Text(Localization.quantityLabel(item.quantity.intValue,
                                            item.formattedPrice))
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
    }

    @ViewBuilder
    func productAttributesView(_ attributes: [OrderItemAttribute]) -> some View {
        let attributeText = attributes.map { "\($0.name): \($0.value)" }.joined(separator: ", ")
        Text(attributeText)
            .font(.posBodySmallRegular())
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
            amount: order.formattedSubtotal
        )
    }

    @ViewBuilder
    func discountTotalRow(_ order: POSOrder) -> some View {
        if let formattedDiscountTotal = order.formattedDiscountTotal {
            totalsRow(
                title: Localization.discountTotalLabel,
                amount: formattedDiscountTotal
            )
        }
    }

    @ViewBuilder
    func taxTotalRow(_ order: POSOrder) -> some View {
        totalsRow(
            title: Localization.taxesLabel,
            amount: order.formattedTotalTax
        )
    }

    @ViewBuilder
    func mainTotalRow(_ order: POSOrder) -> some View {
        totalsRow(
            title: Localization.totalLabel,
            amount: order.formattedTotal,
            titleFont: .posBodyMediumBold
        )
    }

    @ViewBuilder
    func paidAmountRow(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            totalsRow(
                title: Localization.paidLabel,
                amount: order.formattedPaymentTotal,
                titleFont: .posBodyMediumBold
            )

            if order.paymentMethodTitle.isNotEmpty {
                Text(order.paymentMethodTitle)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
    }

    @ViewBuilder
    func refundsSection(_ order: POSOrder) -> some View {
        if !order.refunds.isEmpty {
            ForEach(order.refunds, id: \.refundID) { refund in
                refundRow(refund: refund)
            }

            if let netAmount = order.formattedNetAmount {
                netPaymentRow(netAmount: netAmount)
            }
        }
    }

    @ViewBuilder
    func refundRow(refund: POSOrderRefund) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            totalsRow(
                title: Localization.refundLabel,
                amount: refund.formattedTotal,
                titleFont: .posBodyMediumBold
            )

            if let reason = refund.reason, !reason.isEmpty {
                Text(Localization.reasonLabel(reason))
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
    }

    @ViewBuilder
    func netPaymentRow(netAmount: String) -> some View {
        totalsRow(
            title: Localization.netPaymentLabel,
            amount: netAmount,
            titleFont: .posBodyMediumBold
        )
    }

    @ViewBuilder
    func totalsRow(
        title: String,
        amount: String,
        titleFont: POSFontStyle = .posBodyMediumRegular(),
        amountFont: POSFontStyle = .posBodyMediumRegular()
    ) -> some View {
        HStack {
            Text(title)
                .font(titleFont)
            Spacer()
            Text(amount)
                .font(amountFont)
        }
    }
}

// MARK: - Actions

private extension POSOrderDetailsView {
    enum POSOrderDetailsAction: Identifiable, CaseIterable {
        case emailReceipt

        var id: String { title }

        var title: String {
            switch self {
            case .emailReceipt:
                Localization.emailReceiptActionTitle
            }
        }

        func available(for order: POSOrder) -> Bool {
            switch self {
            case .emailReceipt:
                order.status == .completed
            }
        }
    }

    var actions: [POSOrderDetailsAction] {
        POSOrderDetailsAction.allCases.filter { $0.available(for: order) }
    }

    @ViewBuilder
    func actionsSection(_ actions: [POSOrderDetailsAction]) -> some View {
        HStack {
            ForEach(actions) { action in
                Button(action: {
                    switch action {
                    case .emailReceipt:
                        isShowingEmailReceiptView = true
                    }
                }) {
                    Text(action.title)
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .extraSmall))
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Localization

private enum Localization {
    static func orderTitle(_ orderNumber: String) -> String {
        let format = NSLocalizedString(
            "pos.orderDetailsView.orderTitle",
            value: "Order #%1$@",
            comment: "Order title with order number. %1$@ is the order number."
        )
        return String(format: format, orderNumber)
    }

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
        "pos.orderDetailsView.paidLabel",
        value: "Paid",
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
}

#if DEBUG
#Preview("Order Details") {
    POSOrderDetailsView(
        order: POSPreviewHelpers.makePreviewOrder(),
        onBack: {}
    )
}
#endif
