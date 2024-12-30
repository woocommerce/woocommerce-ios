import struct Yosemite.POSSimpleProduct
import SwiftUI

struct SimpleProductCardView: View {
    private let product: POSSimpleProduct

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    init(product: POSSimpleProduct) {
        self.product = product
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: product.productImageSource,
                             imageSize: Constants.productCardSize * scale,
                             scale: scale)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(product.name)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemNameFont)
                Text(product.formattedPrice)
                    .foregroundStyle(Color.posPrimaryText)
                    .font(Constants.itemPriceFont)
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

private extension SimpleProductCardView {
    enum Constants {
        static let productCardSize: CGFloat = 112
        static let maximumProductCardSize: CGFloat = Constants.productCardSize * 2
        static let cardSpacing: CGFloat = 0
        static let textSpacing: CGFloat = 8
        static let horizontalTextPadding: CGFloat = 32
        static let verticalTextPadding: CGFloat = 8
        static let itemNameFont: POSFontStyle = .posBodyEmphasized
        static let itemPriceFont: POSFontStyle = .posBodyRegular
    }
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
