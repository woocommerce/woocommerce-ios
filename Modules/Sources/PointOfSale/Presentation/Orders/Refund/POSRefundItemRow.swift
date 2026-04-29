import SwiftUI
import typealias Yosemite.OrderItemAttribute

struct POSRefundItemRow: View {
    let item: POSRefundSelectableItem
    let onToggle: () -> Void

    @ScaledMetric private var scale: CGFloat = 1.0

    private var imageSize: CGFloat {
        min(Constants.imageSize * scale, Constants.maximumImageSize)
    }

    var body: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            POSCheckbox(isSelected: item.isSelected, onToggle: onToggle)

            if item.isLumpSum {
                ZStack {
                    Color.posSurfaceContainerLow

                    Image(systemName: "tag")
                        .font(.posButtonSymbolMedium)
                        .foregroundColor(.posOnSurface)
                }
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            } else {
                POSItemImageView(imageSource: item.imageSrc, imageSize: imageSize, scale: 1)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            }

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
        let formattedAttributes: String? = {
            guard item.attributes.isNotEmpty else { return nil }
            let attributeStrings = item.attributes.map { String(format: Localization.attributeFormat, $0.name, $0.value) }
            return ListFormatter.localizedString(byJoining: attributeStrings)
        }()

        if let formattedAttributes {
            return String(format: Localization.accessibilityLabelWithAttributesFormat,
                          item.name,
                          formattedAttributes,
                          item.formattedPrice,
                          selectionState)
        } else {
            return String(format: Localization.accessibilityLabelFormat,
                          item.name,
                          item.formattedPrice,
                          selectionState)
        }
    }
}

private extension POSRefundItemRow {
    enum Constants {
        static let imageSize: CGFloat = 56
        static let maximumImageSize: CGFloat = imageSize * 2
    }

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

        static let attributeFormat = NSLocalizedString(
            "pos.refundItemRow.attributeFormat",
            value: "%1$@: %2$@",
            comment: "Format for a single attribute in accessibility label. %1$@ is the attribute name, %2$@ is the attribute value. Example: 'Size: Medium'"
        )

        static let accessibilityLabelFormat = NSLocalizedString(
            "pos.refundItemRow.accessibilityLabelFormat",
            value: "%1$@, %2$@, %3$@",
            comment: "Accessibility label format for refund item without attributes. %1$@ is the product name, %2$@ is the price, %3$@ is the selection state"
        )

        static let accessibilityLabelWithAttributesFormat = NSLocalizedString(
            "pos.refundItemRow.accessibilityLabelWithAttributesFormat",
            value: "%1$@, %2$@, %3$@, %4$@",
            comment:
                """
                Accessibility label format for refund item with attributes.
                %1$@ is the product name.
                %2$@ is the attributes list.
                %3$@ is the price.
                %4$@ is the selection state.
                """
        )
    }
}

#if DEBUG
#Preview("POSRefundItemRow") {
    VStack(spacing: 0) {
        POSRefundItemRow(
            item: POSRefundSelectableItem(
                itemID: 1,
                name: "Test Product with Long Name",
                imageSrc: nil,
                lineItemTotal: 14.99,
                totalTax: 1.20,
                originalQuantity: 1,
                formattedPrice: "$14.99",
                attributes: [],
                isSelected: true,
                index: 0
            ),
            onToggle: {}
        )

        Divider()

        POSRefundItemRow(
            item: POSRefundSelectableItem(
                itemID: 2,
                name: "Another Product",
                imageSrc: nil,
                lineItemTotal: 9.99,
                totalTax: 0.80,
                originalQuantity: 1,
                formattedPrice: "$9.99",
                attributes: [],
                isSelected: false,
                index: 0
            ),
            onToggle: {}
        )
    }
    .background(Color.posSurfaceBright)
}
#endif
