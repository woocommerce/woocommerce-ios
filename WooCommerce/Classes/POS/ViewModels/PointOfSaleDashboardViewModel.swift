import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [POSProduct]
    @Published var productsInCart: [CartProduct] = []

    @Published var showsCardReaderSheet: Bool = false
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

    let dependencies: PointOfSaleDependencies

    init(products: [POSProduct],
         cardReaderConnectionViewModel: CardReaderConnectionViewModel,
         dependencies: PointOfSaleDependencies) {
        self.products = products
        self.cardReaderConnectionViewModel = cardReaderConnectionViewModel
        self.dependencies = dependencies
    }

    // Creates a unique `CartProduct` from a `Product`, and adds it to the Cart
    func addProductToCart(_ product: POSProduct) {
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

    func showCardReaderConnection() {
        showsCardReaderSheet = true
    }
}
