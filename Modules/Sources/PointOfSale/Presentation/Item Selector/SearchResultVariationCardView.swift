import SwiftUI
import struct Yosemite.POSVariation
import struct Yosemite.POSVariableParentProduct

struct SearchResultVariationCardView: View {
    private let variation: POSVariation
    private let parentProduct: POSVariableParentProduct

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

    private var titleFont: POSFontStyle {
        isCompact ? .posBodySmallBold() : Constants.itemTitleFont
    }

    private var detailFont: POSFontStyle {
        isCompact ? .posBodySmallRegular() : Constants.itemDetailFont
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
                    .font(titleFont)

                Text(variation.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.detailColor)
                    .multilineTextAlignment(.leading)
                    .font(detailFont)

                Text(variation.formattedPrice)
                    .foregroundStyle(Constants.detailColor)
                    .font(detailFont)
            }
            .padding(.horizontal, (isCompact ? POSPadding.small : Constants.horizontalTextPadding) * (1 / scale))
            .padding(.vertical, (isCompact ? 12 : Constants.verticalTextPadding) * (1 / scale))

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
