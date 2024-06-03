public protocol POSItem {
    var itemID: UUID { get }
    var productID: Int64 { get }
    var name: String { get }
    var price: String { get }
}

public protocol POSItemProvider {
    func providePointOfSaleItems() -> [POSItem]
}
