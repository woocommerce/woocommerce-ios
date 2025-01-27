import struct Yosemite.POSSimpleProduct
import SwiftUI

struct SimpleProductCardView: View {
    private let product: POSSimpleProduct

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(product: POSSimpleProduct) {
        self.product = product
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: product.productImageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(product.name)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(product.formattedPrice)
                    .foregroundStyle(Color.posSecondaryText)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: dimension)
        .background(Color.posSecondaryBackground)
        .posItemCardBorderStyles()
    }
}

private extension SimpleProductCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#if DEBUG
#Preview {
    SimpleProductCardView(product: POSSimpleProduct(id: UUID(),
                                                    name: "Product name",
                                                    formattedPrice: "$3.00",
                                                    productID: 123,
                                                    price: "3.00"))
}
#endif
