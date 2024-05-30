import SwiftUI
import protocol Yosemite.POSItem
import struct Yosemite.POSProduct
import struct Yosemite.CartProduct

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published var products: [POSProduct]
    @Published var productsInCart: [CartProduct] = []

    @Published var showsCardReaderSheet: Bool = false
    @Published var showsFilterSheet: Bool = false
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

    init(products: [POSItem],
         cardReaderConnectionViewModel: CardReaderConnectionViewModel) {
        // For the moment we inject POSItem, but only use the POSProduct implementation, since it's the only item type we're using
        // Later we might change this to support other types of items
        self.products = products.compactMap { $0 as? POSProduct }
        self.cardReaderConnectionViewModel = cardReaderConnectionViewModel
    }

    func addProductToCart(_ product: POSProduct) {
        let cartProduct = CartProduct(id: UUID(), product: product, quantity: 1)
        productsInCart.append(cartProduct)
    }

    // Removes a `CartProduct` from the Cart
    func removeProductFromCart(_ cartProduct: CartProduct) {
        productsInCart.removeAll(where: { $0.id == cartProduct.id })
    }

    func submitCart() {
        // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12810
        orderStage = .finalizing
    }

    func addMoreToCart() {
        orderStage = .building
    }

    func showCardReaderConnection() {
        showsCardReaderSheet = true
    }

    func showFilters() {
        showsFilterSheet = true
    }
}

extension PointOfSaleDashboardViewModel {
    // Helper function to populate SwifUI previews
    static func defaultPreview() -> PointOfSaleDashboardViewModel {
        PointOfSaleDashboardViewModel(products: [], cardReaderConnectionViewModel: .init(state: .connectingToReader))
    }
}
