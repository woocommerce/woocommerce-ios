import struct Yosemite.POSSimpleProduct
import SwiftUI

@available(iOS 17.0, *)
struct SimpleProductCardView: View {
    private let product: POSSimpleProduct
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @State private var isFavorite: Bool = false

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
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(product.formattedPrice)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()

            Button(action: {
                if isFavorite {
                    posModel.favoriteProductsService.removeFromFavorite(productID: product.productID)
                } else {
                    posModel.favoriteProductsService.markAsFavorite(productID: product.productID)
                }
                isFavorite.toggle()
            }) {
                Circle()
                    .foregroundColor(.posSurfaceContainerLow)
                    .overlay {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.posButtonSymbolSmall)
                            .foregroundColor(.posOnSurface)
                            .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                    }
                    .frame(width: Constants.favoriteButtonSize, height: Constants.favoriteButtonSize)
            }
            .padding(.trailing, Constants.horizontalTextPadding * (1 / scale))
        }
        .frame(maxWidth: .infinity, idealHeight: dimension)
        .background(Constants.backgroundColor)
        .posItemCardBorderStyles()
        .task {
            isFavorite = await posModel.favoriteProductsService.isFavorite(productID: product.productID)
        }
    }
}

@available(iOS 17.0, *)
private extension SimpleProductCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    SimpleProductCardView(product: POSSimpleProduct(id: UUID(),
                                                    name: "Product name",
                                                    formattedPrice: "$3.00",
                                                    productID: 123,
                                                    price: "3.00"))
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
