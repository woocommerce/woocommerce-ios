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
        HStack {
            if let imageSource = cartItem.item.productImageSource {
                ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                      productImageSize: 60,
                                      scale: scale,
                                      productImageCornerRadius: 1,
                                      foregroundColor: .clear)
            } else {
                // TODO:
                // Handle what we'll show when there's lack of images:
                Rectangle()
                    .frame(width: 60 * scale, height: 60 * scale)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading) {
                Text(cartItem.item.name)
                    .foregroundColor(Color.posPrimaryTexti3)
                Text(cartItem.item.formattedPrice)
                    .foregroundColor(Color.posPrimaryTexti3)
            }
            Spacer()
            Button(action: {
                onItemRemoveTapped?()
            }, label: {
                Image(systemName: "x.circle")
            })
            .frame(width: 56, height: 56, alignment: .trailing)
            .padding(.horizontal, 32)
            .foregroundColor(Color.posIconGrayi3)
        }
        .frame(maxWidth: .infinity, idealHeight: 120)
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
