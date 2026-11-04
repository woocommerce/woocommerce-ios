import struct Yosemite.POSVariation
import SwiftUI

struct VariationCardView: View {
    private let variation: POSVariation

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var dimension: CGFloat {
        min(metrics.productCardSize * scale, metrics.productCardSize * Constants.maximumCardSizeMultiplier)
    }

    init(variation: POSVariation) {
        self.variation = variation
    }

    var body: some View {
        HStack(spacing: metrics.spacing.none) {
            POSItemImageView(imageSource: variation.productImageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: metrics.spacing.xSmall) {
                Text(variation.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(variation.formattedPrice)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, metrics.padding.medium * (1 / scale))
            .padding(.vertical, metrics.padding.small * (1 / scale))
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
