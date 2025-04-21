import SwiftUI

/// Displays a card for a parent product in POS.
@available(iOS 17.0, *)
struct ParentProductCardView: View {
    private let name: String
    private let imageSource: String?
    private let detailText: String
    private let productID: Int64
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @State private var isFavorite: Bool = false

    @ScaledMetric private var scale: CGFloat = 1.0

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(name: String, imageSource: String?, detailText: String, productID: Int64) {
        self.name = name
        self.imageSource = imageSource
        self.detailText = detailText
        self.productID = productID
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: imageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(name)
                    .lineLimit(2)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(detailText)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()

            Button(action: {
                if isFavorite {
                    posModel.favoriteProductsService.removeFromFavorite(productID: productID)
                } else {
                    posModel.favoriteProductsService.markAsFavorite(productID: productID)
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
            isFavorite = await posModel.favoriteProductsService.isFavorite(productID: productID)
        }
    }
}

private typealias Constants = PointOfSaleItemListCardConstants

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    ParentProductCardView(name: "Parent product",
                          imageSource: nil,
                          detailText: "Detail text",
                          productID: 1)
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
