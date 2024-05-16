import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [Product]
    @Published var productsInCart: [CartProduct] = []

    init(products: [Product]) {
        self.products = products
    }

    // Creates a unique `CartProduct` from a `Product`, and adds it to the Cart
    func addProductToCart(_ product: Product) {
        let cartProduct = CartProduct(id: UUID(), product: product, quantity: 1)
        productsInCart.append(cartProduct)
    }

    // Removes a `CartProduct` from the Cart
    func removeProductFromCart(_ cartProduct: CartProduct) {
        productsInCart.removeAll(where: { $0.id == cartProduct.id })
    }

    func submitCart() {
        debugPrint("Not implemented")
    }
}
