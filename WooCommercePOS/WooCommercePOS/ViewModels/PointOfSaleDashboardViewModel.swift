import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [Product]
    @Published var productsInOrder: [Product] = []

    init(products: [Product]) {
        self.products = products
    }

    func callbackFromProductSelector(_ product: Product) {
        debugPrint("Product selector callback: \(product.name)")
    }

    func callbackFromOrder() {
        debugPrint("Order callback")
    }
}
