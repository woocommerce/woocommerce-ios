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
        HStack(spacing: 0) {
            if let imageSource = cartItem.item.productImageSource {
                ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                      productImageSize: Constants.productCardHeight,
                                      scale: scale,
                                      productImageCornerRadius: Constants.productCardCornerRadius,
                                      foregroundColor: .clear)
            } else {
                // TODO:
                // Handle what we'll show when there's lack of images:
                Rectangle()
                    .frame(width: Constants.productCardHeight * scale,
                           height: Constants.productCardHeight * scale)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading) {
                Text(cartItem.item.name)
                    .foregroundColor(Color.posPrimaryTexti3)
                Text(cartItem.item.formattedPrice)
                    .foregroundColor(Color.posPrimaryTexti3)
            }
            Spacer()
            if let onItemRemoveTapped {
                Button(action: {
                    onItemRemoveTapped()
                }, label: {
                    Image(systemName: "x.circle")
                })
                .frame(width: 56, height: 56, alignment: .trailing)
                .padding(.horizontal, 32)
                .foregroundColor(Color.posIconGrayi3)
            }
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardHeight)
        .background(Color.posBackgroundGreyi3)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.productCardCornerRadius)
                .stroke(Color.black, lineWidth: Constants.nilOutline)
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.productCardCornerRadius))
        .padding(.horizontal, Constants.horizontalPadding)
    }
}

private extension ItemRowView {
    enum Constants {
        static let productCardHeight: CGFloat = 64
        static let productCardCornerRadius: CGFloat = 20
        // The use of stroke means the shape is rendered as an outline (border) rather than a filled shape,
        // since we still have to give it a value, we use 0 so it renders no border but it's shaped as one.
        static let nilOutline: CGFloat = 0
        static let horizontalPadding: CGFloat = 32
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
