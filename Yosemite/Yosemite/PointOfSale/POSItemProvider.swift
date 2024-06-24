public protocol POSItem {
    var itemID: UUID { get }
    var productID: Int64 { get }
    var name: String { get }
    var price: String { get }
    var formattedPrice: String { get }
    var itemCategories: [String] { get }
    var productImageSource: String? { get }
    var productType: ProductType { get }
}

public protocol POSItemProvider {
    func providePointOfSaleItemsFromStorage() -> [POSItem]
    func providePointOfSaleItemsFromNetwork() async throws -> [POSItem]
}
