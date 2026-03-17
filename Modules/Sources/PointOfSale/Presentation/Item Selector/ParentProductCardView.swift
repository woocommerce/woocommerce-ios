import SwiftUI

/// Displays a card for a parent product in POS.
struct ParentProductCardView: View {
    private let name: String
    private let imageSource: String?
    private let detailText: String

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var dimension: CGFloat {
        let baseSize: CGFloat = isCompact ? 64 : Constants.productCardSize
        let maxSize: CGFloat = isCompact ? 96 : Constants.maximumProductCardSize
        return min(baseSize * scale, maxSize)
    }

    init(name: String, imageSource: String?, detailText: String) {
        self.name = name
        self.imageSource = imageSource
        self.detailText = detailText
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: imageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(detailText)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, (isCompact ? POSPadding.small : Constants.horizontalTextPadding) * (1 / scale))
            .padding(.vertical, (isCompact ? POSPadding.xSmall : Constants.verticalTextPadding) * (1 / scale))
            Spacer()

            Image(systemName: "chevron.forward")
                .accessibilityHidden(true)
                .font(.posButtonSymbolSmall)
                .foregroundStyle(Color.posOnSurfaceVariantLowest)
                .padding(.horizontal, POSPadding.medium * (1 / scale))
        }
        .frame(maxWidth: .infinity, idealHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
    }
}

private typealias Constants = PointOfSaleItemListCardConstants

#if DEBUG
#Preview {
    ParentProductCardView(name: "Parent product",
                          imageSource: nil,
                          detailText: "Detail text")
}
#endif
