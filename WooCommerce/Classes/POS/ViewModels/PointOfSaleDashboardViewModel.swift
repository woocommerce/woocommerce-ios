import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [POSProduct]
    @Published var productsInCart: [CartProduct] = []

    @Published var showsCardReaderSheet: Bool = false
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

    init(products: [POSProduct],
         cardReaderConnectionViewModel: CardReaderConnectionViewModel) {
        self.products = products
        self.cardReaderConnectionViewModel = cardReaderConnectionViewModel
    }

    func addProductToCart(_ product: POSProduct) {
        if product.stockQuantity > 0 {
            let cartProduct = CartProduct(id: UUID(), product: product, quantity: 1)
            productsInCart.append(cartProduct)
        } else {
            // TODO: Handle out of stock
            return
        }
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
