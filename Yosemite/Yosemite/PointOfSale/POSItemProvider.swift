public protocol POSItem {
    var itemID: UUID { get }
    var productID: Int64 { get }
    var name: String { get }
    var price: String { get }
    var imageURL: URL { get }
    var details: [String] { get }

    func makeCartItem() -> CartItem
}

public protocol POSItemProvider {
    func providePointOfSaleItems() -> [POSItem]
}
