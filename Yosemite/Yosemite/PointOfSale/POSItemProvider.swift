public protocol POSItem {
    var itemID: UUID { get }
    var productID: Int64 { get }
    var name: String { get }
    var price: String { get }
    var formattedPrice: String { get }
    var itemCategories: [String] { get }
    var productImageSource: String? { get }
}

public protocol POSItemProvider {
    func providePointOfSaleItems() -> [POSItem]
}
