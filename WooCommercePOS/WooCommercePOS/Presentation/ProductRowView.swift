import SwiftUI

struct ProductRowView: View {
    private let cartProduct: CartProduct
    private var onProductRemoveTapped: (() -> Void)?

    init(cartProduct: CartProduct, onProductRemoveTapped: (() -> Void)? = nil) {
        self.cartProduct = cartProduct
        self.onProductRemoveTapped = onProductRemoveTapped
    }

    var body: some View {
        HStack {
            Text(cartProduct.product.name)
                .foregroundColor(Color.primaryText)
            Button(action: {
                onProductRemoveTapped?()
            }, label: {
                Image(uiImage: .remove)
            })
        }
        .frame(maxWidth: .infinity)
        .border(Color.gray, width: 1)
        .foregroundColor(Color.tertiaryBackground)
    }
}

#Preview {
    ProductRowView(cartProduct: CartProduct(
        id: UUID(), product: Product(itemID: UUID(), productID: 0, name: "Product name", price: "$2.00"),
        quantity: 2))
}
