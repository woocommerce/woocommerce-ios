import SwiftUI

struct ProductRowView: View {

    private let cartProduct: CartProduct

    init(cartProduct: CartProduct) {
        self.cartProduct = cartProduct
    }

    var body: some View {
        Text(cartProduct.product.name)
            .frame(maxWidth: .infinity)
            .border(Color.gray, width: 1)
    }
}

#Preview {
    ProductRowView(cartProduct: CartProduct(
        product: Product(itemID: UUID(), productID: 0, name: "Product name", price: "$2.00"),
        quantity: 2))
}
