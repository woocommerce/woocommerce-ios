import SwiftUI

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [Product]
    @Published var productsInOrder: [Product] = []

    @Published var showsCardReaderSheet: Bool = false
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

    init(products: [Product],
         cardReaderConnectionViewModel: CardReaderConnectionViewModel) {
        self.products = products
        self.cardReaderConnectionViewModel = cardReaderConnectionViewModel
    }

    func addProductToCart(_ product: Product) {
        debugPrint("Not implemented")
    }

    func submitCart() {
        debugPrint("Not implemented")
    }

    func showCardReaderConnection() {
        showsCardReaderSheet = true
    }
}
