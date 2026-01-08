import SwiftUI
import typealias Yosemite.OrderItemAttribute

struct POSRefundItemRow: View {
    let item: POSRefundSelectableItem
    let onToggle: () -> Void

    private let imageSize: CGFloat = 40

    var body: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            POSCheckbox(isSelected: item.isSelected, onToggle: onToggle)

            POSItemImageView(imageSource: item.imageSrc, imageSize: imageSize, scale: 1)
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))

            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(item.name)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(Color.posOnSurface)
                    .lineLimit(2)

                if !item.attributes.isEmpty {
                    attributesView(item.attributes)
                }

                Text(Localization.quantityLabel(item.quantity.intValue, item.formattedPrice))
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }

            Spacer()

            Text(item.formattedTotal)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .padding(POSPadding.medium)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(item.isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private func attributesView(_ attributes: [OrderItemAttribute]) -> some View {
        let attributeText = attributes.map { "\($0.name): \($0.value)" }.joined(separator: ", ")
        Text(attributeText)
            .font(.posBodySmallRegular())
            .foregroundStyle(Color.posOnSurfaceVariantHighest)
            .lineLimit(1)
    }

    private var accessibilityLabel: String {
        let selectionState = item.isSelected ? Localization.selectedState : Localization.unselectedState
        let attributesText = item.attributes.isEmpty ? nil : item.attributes.map { "\($0.name): \($0.value)" }.joined(separator: ", ")

        var label = "\(item.name)"
        if let attributesText {
            label += ", \(attributesText)"
        }
        label += ", \(Localization.quantityLabel(item.quantity.intValue, item.formattedPrice))"
        label += ", \(Localization.totalLabel(item.formattedTotal))"
        label += ", \(selectionState)"

        return label
    }
}

private extension POSRefundItemRow {
    enum Localization {
        static func quantityLabel(_ quantity: Int, _ unitPrice: String) -> String {
            let format = NSLocalizedString(
                "pos.refundItemRow.quantityLabel",
                value: "%1$d × %2$@",
                comment: "Product quantity and price label for refund item. %1$d is the quantity, %2$@ is the unit price."
            )
            return String(format: format, quantity, unitPrice)
        }

        static func totalLabel(_ total: String) -> String {
            let format = NSLocalizedString(
                "pos.refundItemRow.totalLabel",
                value: "Total %1$@",
                comment: "Total price label for accessibility. %1$@ is the total amount."
            )
            return String(format: format, total)
        }

        static let selectedState = NSLocalizedString(
            "pos.refundItemRow.selectedState",
            value: "Selected for refund",
            comment: "Accessibility state when item is selected for refund"
        )

        static let unselectedState = NSLocalizedString(
            "pos.refundItemRow.unselectedState",
            value: "Not selected for refund",
            comment: "Accessibility state when item is not selected for refund"
        )
    }
}

#if DEBUG
#Preview("POSRefundItemRow") {
    VStack(spacing: 0) {
        POSRefundItemRow(
            item: POSRefundSelectableItem(
                id: 1,
                name: "Test Product with Long Name",
                imageSrc: nil,
                formattedTotal: "$29.99",
                quantity: 2,
                formattedPrice: "$14.99",
                attributes: [],
                isSelected: true
            ),
            onToggle: {}
        )

        Divider()

        POSRefundItemRow(
            item: POSRefundSelectableItem(
                id: 2,
                name: "Another Product",
                imageSrc: nil,
                formattedTotal: "$9.99",
                quantity: 1,
                formattedPrice: "$9.99",
                attributes: [],
                isSelected: false
            ),
            onToggle: {}
        )
    }
    .background(Color.posSurfaceBright)
}
#endif
