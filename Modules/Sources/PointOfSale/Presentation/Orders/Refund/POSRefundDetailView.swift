import SwiftUI
import struct Yosemite.POSOrderRefund
import struct Yosemite.POSRefundItem

struct POSRefundDetailView: View {
    let refund: POSOrderRefund
    let title: String
    let paymentMethodDescription: String
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    productRows
                    Divider()
                        .overlay(Color.posOutlineVariant.opacity(0.5))
                    summaryRows
                    Divider()
                        .overlay(Color.posOutlineVariant.opacity(0.5))
                    refundTotalSection
                }
                .padding(.horizontal, POSPadding.xLarge)
                .padding(.bottom, POSPadding.xLarge)
            }
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
    }
}

// MARK: - Subviews

private extension POSRefundDetailView {
    var headerView: some View {
        HStack {
            Text(title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(1)
            Spacer()
            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var productRows: some View {
        VStack(spacing: POSSpacing.none) {
            ForEach(refund.items) { item in
                productRow(item: item)

                if item.id != refund.items.last?.id {
                    Divider()
                        .overlay(Color.posOutlineVariant.opacity(0.5))
                        .padding(.vertical, POSSpacing.small)
                }
            }
        }
    }

    func productRow(item: POSRefundItem) -> some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            POSItemImageView(imageSource: item.imageSrc, imageSize: 56, scale: 1)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))

            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(item.name)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .fixedSize(horizontal: false, vertical: true)

                Text(Localization.quantityLabel(item.quantity.intValue, item.formattedPrice))
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }

            Spacer()

            Text(item.formattedTotal)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
    }

    var summaryRows: some View {
        VStack(spacing: POSSpacing.small) {
            summaryRow(
                label: Localization.itemsSubtotalLabel(refund.itemCount),
                value: refund.formattedItemsSubtotal
            )
            summaryRow(
                label: Localization.taxLabel,
                value: refund.formattedTax
            )
        }
    }

    var refundTotalSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            HStack {
                Text(Localization.refundTotalLabel)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posOnSurface)
                Spacer()
                Text(refund.formattedTotal)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posOnSurface)
            }
            Text(paymentMethodDescription)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
        }
    }

    func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
            Spacer()
            Text(value)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurface)
        }
    }
}

// MARK: - Localization

private extension POSRefundDetailView {
    enum Localization {
        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundDetailView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund detail dialog"
        )

        static func quantityLabel(_ quantity: Int, _ unitPrice: String) -> String {
            let format = NSLocalizedString(
                "pos.refundDetailView.quantityLabel",
                value: "%1$d × %2$@",
                comment: "Product quantity and price label. %1$d is the quantity, %2$@ is the unit price."
            )
            return String(format: format, quantity, unitPrice)
        }

        static func itemsSubtotalLabel(_ count: Int) -> String {
            let singular = NSLocalizedString(
                "pos.refundDetailView.itemsSubtotalFormat.singular",
                value: "Items subtotal (%1$d item)",
                comment: "Label for items subtotal row in refund detail when there is 1 item. %1$d is the number of items."
            )
            let plural = NSLocalizedString(
                "pos.refundDetailView.itemsSubtotalFormat.plural",
                value: "Items subtotal (%1$d items)",
                comment: "Label for items subtotal row in refund detail when there are multiple items. %1$d is the number of items."
            )
            return String.pluralize(count, singular: singular, plural: plural)
        }

        static let taxLabel = NSLocalizedString(
            "pos.refundDetailView.taxLabel",
            value: "Tax",
            comment: "Label for tax row in refund detail"
        )

        static let refundTotalLabel = NSLocalizedString(
            "pos.refundDetailView.refundTotalLabel",
            value: "Refund total",
            comment: "Label for refund total row in refund detail"
        )
    }
}

#if DEBUG
#Preview("Refund Detail - Single Item") {
    POSRefundDetailView(
        refund: POSOrderRefund(
            refundID: 1,
            formattedTotal: "$21.60",
            reason: "Customer request",
            dateCreated: Date(),
            items: [
                POSRefundItem(refundedItemID: 1, quantity: 1, name: "Cup", formattedPrice: "$18.00", formattedTotal: "$18.00", imageSrc: nil)
            ],
            formattedItemsSubtotal: "$18.00",
            formattedTax: "$3.60",
            itemCount: 1
        ),
        title: "Refund #1",
        paymentMethodDescription: "Via WooCommerce In-Person Payments",
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("Refund Detail - Multiple Items") {
    POSRefundDetailView(
        refund: POSOrderRefund(
            refundID: 2,
            formattedTotal: "$45.00",
            reason: nil,
            dateCreated: Date(),
            items: [
                POSRefundItem(refundedItemID: 1, quantity: 2, name: "Hario V60 Dripper", formattedPrice: "$12.00", formattedTotal: "$24.00", imageSrc: nil),
                POSRefundItem(refundedItemID: 2, quantity: 1, name: "Cup", formattedPrice: "$18.00", formattedTotal: "$18.00", imageSrc: nil)
            ],
            formattedItemsSubtotal: "$42.00",
            formattedTax: "$3.00",
            itemCount: 3
        ),
        title: "Refund #2",
        paymentMethodDescription: "Via WooCommerce In-Person Payments",
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
