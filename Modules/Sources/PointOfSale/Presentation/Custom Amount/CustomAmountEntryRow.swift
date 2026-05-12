import SwiftUI

struct CustomAmountEntryRow: View {
    let onTap: () -> Void

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.cardSpacing) {
                ZStack {
                    Color.posSurfaceContainerLow

                    // Composite of `tag` + a `plus.circle.fill` badge to convey "add a custom amount".
                    // Avoids `tag.badge.plus`, which is iOS 18+ only (SF Symbols 6) and renders blank
                    // on our iOS 17 floor.
                    Image(systemName: "tag")
                        .font(.posButtonSymbolMedium)
                        .foregroundColor(.posOnSurface)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "plus.circle.fill")
                                .font(.posBodyLargeBold)
                                .foregroundStyle(Color.posOnSurface, Color.posSurfaceContainerLow)
                                .offset(x: 8, y: 6)
                        }
                }
                .frame(width: dimension, height: dimension)

                VStack(alignment: .leading, spacing: Constants.textSpacing) {
                    Text(Localization.title)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                        .foregroundStyle(Constants.titleColor)
                        .multilineTextAlignment(.leading)
                        .font(Constants.itemTitleFont)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(Localization.subtitle)
                        .foregroundStyle(Constants.detailColor)
                        .font(Constants.itemDetailFont)
                }
                .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
                .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
                Spacer()
            }
            .frame(maxWidth: .infinity, idealHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
            .background(Constants.backgroundColor)
            .posItemCardBorderStyles()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Localization.title))
        .accessibilityHint(Text(Localization.subtitle))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("pos-custom-amount-entry-row")
    }
}

private extension CustomAmountEntryRow {
    typealias Constants = PointOfSaleItemListCardConstants

    enum Localization {
        static let title = NSLocalizedString(
            "pos.itemList.customAmountEntryRow.title",
            value: "Custom amount",
            comment: "Title for the row in the Point of Sale products list that opens the custom amount form.")
        static let subtitle = NSLocalizedString(
            "pos.itemList.customAmountEntryRow.subtitle",
            value: "Add a one-off charge.",
            comment: "Subtitle for the row in the Point of Sale products list that opens the custom amount form.")
    }
}

#if DEBUG
#Preview("iPad") {
    CustomAmountEntryRow(onTap: {})
        .padding()
        .frame(maxWidth: 320)
}

#Preview("iPad — Accessibility XL") {
    CustomAmountEntryRow(onTap: {})
        .padding()
        .frame(maxWidth: 320)
        .dynamicTypeSize(.accessibility3)
}
#endif
