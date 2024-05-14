import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [Product]
    @Published var productsInCart: [CartProduct] = []

    init(products: [Product]) {
        self.products = products
    }

    func addProductToCart(_ product: Product) {
        let cartProduct = CartProduct(product: product, quantity: 1)
        productsInCart.append(cartProduct)
    }

    func removeProductFromCart(_ product: Product) {
        debugPrint("Not implemented")
    }

    func submitCart() {
        debugPrint("Not implemented")
    }
}
