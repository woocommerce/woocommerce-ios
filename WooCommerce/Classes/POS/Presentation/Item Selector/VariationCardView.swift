import struct Yosemite.POSVariation
import SwiftUI

struct VariationCardView: View {
    private let variation: POSVariation

    @ScaledMetric private var scale: CGFloat = 1.0

    init(variation: POSVariation) {
        self.variation = variation
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: variation.productImageSource,
                             imageSize: Constants.productCardSize * scale,
                             scale: scale)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)
            .clipped()

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(variation.name)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemNameFont)

                Text(variation.formattedPrice)
                    .foregroundStyle(Color.posSecondaryText)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(Color.posSecondaryBackground)
        .posItemCardBorderStyles()
    }
}

private extension VariationCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#Preview("Variation without image") {
    let variation = POSVariation(id: .init(),
                                 name: "500ml, double shot",
                                 formattedPrice: "$5.00",
                                 price: "5.00",
                                 productID: 134,
                                 variationID: 256,
                                 parentProductName: "Coffee")
    VariationCardView(variation: variation)
}

#Preview("Variation with image") {
    let variation = POSVariation(id: .init(),
                                 name: "500ml, double shot",
                                 formattedPrice: "$5.00",
                                 price: "5.00",
                                 productImageSource: "https://pd.w.org/2024/12/986762d0d4d4cf17.82435881-scaled.jpeg",
                                 productID: 134,
                                 variationID: 256,
                                 parentProductName: "Coffee")
    VariationCardView(variation: variation)
}
