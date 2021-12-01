import Yosemite

/// View model for `AddProduct`.
///
final class AddProductViewModel: ObservableObject {
    /// List of products to display
    ///
    let products: [Product]

    /// View models for each product row
    ///
    let productRowViewModels: [ProductRowViewModel]

    init(products: [Product]) {
        self.products = products
        self.productRowViewModels = products.map { .init(product: $0, canChangeQuantity: false) }
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
//
extension AddProductViewModel {
    static let sampleProducts = [Product().copy(productID: 1, name: "Bird of Paradise Tree", sku: "", price: "20", stockStatusKey: "outofstock"),
                                 Product().copy(productID: 2, name: "Love Ficus", sku: "123456", price: "7.50", stockQuantity: 7, stockStatusKey: "instock"),
                                 Product().copy(productID: 3, name: "Zanzibar Gem", sku: "654321", price: "", stockQuantity: 0, stockStatusKey: "onbackorder")]
}
