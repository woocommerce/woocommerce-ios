import SwiftUI
import typealias Yosemite.OrderItemAttribute

struct POSRefundItemRow: View {
    let item: POSRefundSelectableItem
    let onToggle: () -> Void

    private let imageSize: CGFloat = 56

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

                Text(item.formattedPrice)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }

            Spacer()
        }
        .padding(.vertical, POSPadding.medium)
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
        label += ", \(item.formattedPrice)"
        label += ", \(selectionState)"

        return label
    }
}

private extension POSRefundItemRow {
    enum Localization {
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
