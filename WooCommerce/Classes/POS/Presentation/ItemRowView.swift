import SwiftUI

struct ItemRowView: View {
    private let cartItem: CartItem
    private let onItemRemoveTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0

    init(cartItem: CartItem, onItemRemoveTapped: (() -> Void)? = nil) {
        self.cartItem = cartItem
        self.onItemRemoveTapped = onItemRemoveTapped
    }

    var body: some View {
        HStack(spacing: Constants.horizontalCardSpacing) {
            if let imageSource = cartItem.item.productImageSource {
                ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                      productImageSize: Constants.productCardHeight,
                                      scale: scale,
                                      foregroundColor: .clear)
            } else {
                // TODO:
                // Handle what we'll show when there's lack of images:
                Rectangle()
                    .frame(width: Constants.productCardHeight * scale,
                           height: Constants.productCardHeight * scale)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: Constants.itemNameAndPriceSpacing) {
                Text(cartItem.item.name)
                    .foregroundColor(Color.primaryText)
                    .font(Constants.itemNameFont)
                    .padding(.horizontal, Constants.horizontalElementSpacing)
                Text(cartItem.item.formattedPrice)
                    .foregroundColor(Color.primaryText)
                    .font(Constants.itemPriceFont)
                    .padding(.horizontal, Constants.horizontalElementSpacing)
            }
            Spacer()
            if let onItemRemoveTapped {
                Button(action: {
                    onItemRemoveTapped()
                }, label: {
                    HStack {
                        Spacer()
                        Image(PointOfSaleAssets.removeCartItem.imageName)
                        Spacer()
                    }
                })
                .frame(width: Constants.buttonWidth,
                       height: Constants.buttonWidth,
                       alignment: .trailing)
                .foregroundColor(Color.posIconGrayi3)
            }
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardHeight)
        .background(Color.posBackgroundWhitei3)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.productCardCornerRadius)
                .stroke(Color.black, lineWidth: Constants.nilOutline)
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.productCardCornerRadius))
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }
}

private extension ItemRowView {
    enum Constants {
        static let productCardHeight: CGFloat = 72
        static let productCardCornerRadius: CGFloat = 8
        // The use of stroke means the shape is rendered as an outline (border) rather than a filled shape,
        // since we still have to give it a value, we use 0 so it renders no border but it's shaped as one.
        static let nilOutline: CGFloat = 0
        static let verticalPadding: CGFloat = 4
        static let horizontalPadding: CGFloat = 16
        static let horizontalCardSpacing: CGFloat = 0
        static let horizontalElementSpacing: CGFloat = 16
        static let buttonWidth: CGFloat = 56
        static let itemNameAndPriceSpacing: CGFloat = 8
        static let itemNameFont: POSFontStyle = .posDetailEmphasized
        static let itemPriceFont: POSFontStyle = .posDetailLight
    }
}

#if DEBUG
#Preview {
    ItemRowView(cartItem: CartItem(id: UUID(),
                                   item: POSItemProviderPreview().providePointOfSaleItem(),
                                   quantity: 2),
                onItemRemoveTapped: { })
}
#endif
