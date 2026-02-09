import SwiftUI
import struct Yosemite.POSVariation
import struct Yosemite.POSVariableParentProduct

struct SearchResultVariationCardView: View {
    private let variation: POSVariation
    private let parentProduct: POSVariableParentProduct

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(variation: POSVariation, parentProduct: POSVariableParentProduct) {
        self.variation = variation
        self.parentProduct = parentProduct
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(
                imageSource: variation.productImageSource ?? parentProduct.productImageSource,
                imageSize: dimension,
                scale: 1
            )
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(parentProduct.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(variation.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.detailColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemDetailFont)

                Text(variation.formattedPrice)
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
}

private extension SearchResultVariationCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#if DEBUG
#Preview("Search result variation") {
    let variation = POSVariation(
        id: .init(underlyingType: .variation, itemID: 100),
        name: "Large, Blue",
        formattedPrice: "$25.00",
        price: "25.00",
        productID: 1,
        variationID: 100,
        parentProductName: "T-Shirt"
    )
    let parentProduct = POSVariableParentProduct(
        id: .init(underlyingType: .product, itemID: 1),
        name: "T-Shirt",
        productImageSource: nil,
        productID: 1
    )
    SearchResultVariationCardView(variation: variation, parentProduct: parentProduct)
}
#endif
