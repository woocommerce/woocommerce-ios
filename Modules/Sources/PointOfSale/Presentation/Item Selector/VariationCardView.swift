import struct Yosemite.POSVariation
import SwiftUI

struct VariationCardView: View {
    private let variation: POSVariation

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var dimension: CGFloat {
        let baseSize: CGFloat = isCompact ? 56 : Constants.productCardSize
        let maxSize: CGFloat = isCompact ? 84 : Constants.maximumProductCardSize
        return min(baseSize * scale, maxSize)
    }

    private var titleFont: POSFontStyle {
        isCompact ? .posBodySmallBold() : Constants.itemTitleFont
    }

    private var detailFont: POSFontStyle {
        isCompact ? .posBodySmallRegular() : Constants.itemDetailFont
    }

    init(variation: POSVariation) {
        self.variation = variation
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: variation.productImageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(variation.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(titleFont)

                Text(variation.formattedPrice)
                    .foregroundStyle(Constants.detailColor)
                    .font(detailFont)
            }
            .padding(.horizontal, (isCompact ? POSPadding.small : Constants.horizontalTextPadding) * (1 / scale))
            .padding(.vertical, (isCompact ? POSPadding.small : Constants.verticalTextPadding) * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
    }
}

private extension VariationCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#Preview("Variation without image") {
    let variation = POSVariation(id: .init(underlyingType: .variation, itemID: 256),
                                 name: "500ml, double shot",
                                 formattedPrice: "$5.00",
                                 price: "5.00",
                                 productID: 134,
                                 variationID: 256,
                                 parentProductName: "Coffee")
    VariationCardView(variation: variation)
}

#Preview("Variation with image") {
    let variation = POSVariation(id: .init(underlyingType: .variation, itemID: 257),
                                 name: "500ml, double shot",
                                 formattedPrice: "$5.00",
                                 price: "5.00",
                                 productImageSource: "https://pd.w.org/2024/12/986762d0d4d4cf17.82435881-scaled.jpeg",
                                 productID: 134,
                                 variationID: 257,
                                 parentProductName: "Coffee")
    VariationCardView(variation: variation)
}
