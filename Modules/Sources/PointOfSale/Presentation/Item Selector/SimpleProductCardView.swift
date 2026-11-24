import struct Yosemite.POSSimpleProduct
import SwiftUI

struct SimpleProductCardView: View {
    private let product: POSSimpleProduct

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var dimension: CGFloat {
        Constants.imageSize(metrics: metrics, scale: scale, dynamicTypeSize: dynamicTypeSize)
    }

    init(product: POSSimpleProduct) {
        self.product = product
    }

    var body: some View {
        POSItemCardLayout {
            POSItemImageView(imageSource: product.productImageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)
        } details: {
            VStack(alignment: .leading, spacing: metrics.spacing.xSmall) {
                Text(product.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)
                    .fixedSize(horizontal: false, vertical: true)

                Text(product.formattedPrice)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
            }
        }
        .frame(maxWidth: .infinity, idealHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
    }
}

private extension SimpleProductCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#if DEBUG
#Preview {
    SimpleProductCardView(product: POSSimpleProduct(id: .init(underlyingType: .product, itemID: 123),
                                                    name: "Product name",
                                                    formattedPrice: "$3.00",
                                                    productID: 123,
                                                    price: "3.00",
                                                    manageStock: false,
                                                    stockQuantity: nil,
                                                    stockStatusKey: "instock"))
}
#endif
