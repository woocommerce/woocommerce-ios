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

    var formattedStockQuantity: String {
        if !product.manageStock {
            return "Not managed"
        }
        if let stock = product.stockQuantity {
            if stock < 0 {
               return "Out of stock!"
           } else {
               return "✨💖 \(stock) in stock 💖✨"
           }
        }
        return "☠️ unhandled!"
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: product.productImageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(product.name)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)
                    .fixedSize(horizontal: false, vertical: true)

                Text(product.formattedPrice)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
                Text(formattedStockQuantity)
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

private extension SimpleProductCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#if DEBUG
#Preview {
    SimpleProductCardView(product: POSSimpleProduct(id: UUID(),
                                                    name: "Product name",
                                                    formattedPrice: "$3.00",
                                                    productID: 123,
                                                    price: "3.00",
                                                    manageStock: true,
                                                    stockQuantity: 3,
                                                    stockStatusKey: "in stock"))
}
#endif
