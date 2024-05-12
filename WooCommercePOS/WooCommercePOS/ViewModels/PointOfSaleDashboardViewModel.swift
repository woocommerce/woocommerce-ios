import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [Product]
    @Published var productsInOrder: [Product] = []

    init(products: [Product]) {
        self.products = products
    }

    func callbackFromProductSelector(_ product: Product) {
        debugPrint("Not implemented")
    }

    func callbackFromOrder() {
        debugPrint("Not implemented")
    }
}
