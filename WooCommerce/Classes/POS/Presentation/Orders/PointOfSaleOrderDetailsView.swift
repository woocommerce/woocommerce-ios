import SwiftUI
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund
import enum Yosemite.OrderStatusEnum
import typealias Yosemite.OrderItemAttribute

struct PointOfSaleOrderDetailsView: View {
    let order: POSOrder
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let helper = PointOfSaleOrderDetailsViewHelper()

    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
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
    }
}

// MARK: - Main Sections

private extension PointOfSaleOrderDetailsView {
    @ViewBuilder
    func productsSection(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.productsTitle)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.small) {
                ForEach(order.lineItems, id: \.itemID) { item in
                    productRow(item: item, order: order)
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

private extension PointOfSaleOrderDetailsView {
    @ViewBuilder
    func headerBottomContent(for order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(DateFormatter.dateAndTimeFormatter.string(from: order.dateCreated))
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

private extension PointOfSaleOrderDetailsView {
    @ViewBuilder
    func productRow(item: POSOrderItem, order: POSOrder) -> some View {
        HStack(alignment: .top, spacing: POSSpacing.medium) {
            productImageView(for: item)
            productDetailsView(item: item, order: order)
            Spacer()
            productTotalView(item: item, order: order)
        }
        .padding(.vertical, POSPadding.small)
    }

    @ViewBuilder
    func productImageView(for item: POSOrderItem) -> some View {
        POSItemImageView(imageSource: imageSource(for: item), imageSize: 40, scale: 1)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
    }

    func imageSource(for item: POSOrderItem) -> String? {
        // TODO: Will be addressed in the following PR
        return "\(item.productID - item.variationID)"
    }

    @ViewBuilder
    func productDetailsView(item: POSOrderItem, order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(item.name)
                .font(.posBodyMediumBold)
                .foregroundStyle(Color.posOnSurface)
                .fixedSize(horizontal: false, vertical: true)

            if !item.attributes.isEmpty {
                productAttributesView(item.attributes)
            }

            Text(Localization.quantityLabel(item.quantity.intValue, helper.formatItemPrice(item.price, with: order.currency)))
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
    func productTotalView(item: POSOrderItem, order: POSOrder) -> some View {
        Text(helper.formatItemTotal(item.total, with: order.currency))
            .font(.posBodyMediumRegular())
            .foregroundStyle(Color.posOnSurface)
    }
}

// MARK: - Totals Components

private extension PointOfSaleOrderDetailsView {
    @ViewBuilder
    func productsSubtotalRow(_ order: POSOrder) -> some View {
        if helper.shouldShowProductsSubtotal(for: order) {
            totalsRow(
                title: Localization.productsLabel,
                amount: helper.productsSubtotal(for: order)
            )
        }
    }

    @ViewBuilder
    func discountTotalRow(_ order: POSOrder) -> some View {
        if helper.shouldShowDiscount(for: order),
           let discountAmount = helper.formattedDiscountTotal(for: order) {
            totalsRow(
                title: Localization.discountTotalLabel,
                amount: discountAmount
            )
        }
    }

    @ViewBuilder
    func taxTotalRow(_ order: POSOrder) -> some View {
        if let taxAmount = helper.formattedTaxTotal(for: order) {
            totalsRow(
                title: Localization.taxesLabel,
                amount: taxAmount
            )
        }
    }

    @ViewBuilder
    func mainTotalRow(_ order: POSOrder) -> some View {
        totalsRow(
            title: Localization.totalLabel,
            amount: helper.formattedOrderTotal(for: order),
            titleFont: .posBodyMediumBold
        )
    }

    @ViewBuilder
    func paidAmountRow(_ order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            totalsRow(
                title: Localization.paidLabel,
                amount: helper.formattedPaidAmount(for: order),
                titleFont: .posBodyMediumBold
            )

            Text(order.paymentMethodTitle)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
    }

    @ViewBuilder
    func refundsSection(_ order: POSOrder) -> some View {
        if !order.refunds.isEmpty {
            ForEach(order.refunds, id: \.refundID) { refund in
                refundRow(refund: refund, order: order)
            }

            if helper.shouldShowNetPayment(for: order) {
                netPaymentRow(order: order)
            }
        }
    }

    @ViewBuilder
    func refundRow(refund: POSOrderRefund, order: POSOrder) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            totalsRow(
                title: Localization.refundLabel,
                amount: helper.formattedRefundTotal(refund, currency: order.currency),
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
    func netPaymentRow(order: POSOrder) -> some View {
        totalsRow(
            title: Localization.netPaymentLabel,
            amount: helper.netPaymentAfterRefunds(for: order),
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
}

#if DEBUG
#Preview("Order Details") {
    PointOfSaleOrderDetailsView(
        order: POSPreviewHelpers.makePreviewOrder(),
        onBack: {}
    )
}
#endif
