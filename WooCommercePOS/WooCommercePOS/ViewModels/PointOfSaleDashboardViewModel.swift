import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [Product]
    @Published var productsInOrder: [Product] = []

    init(products: [Product]) {
        self.products = products
    }

    func addProductToCart(_ product: Product) {
        debugPrint("Not implemented")
    }

    func submitCart() {
        debugPrint("Not implemented")
    }
}
