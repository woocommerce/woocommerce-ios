public protocol POSItem {
    var itemID: UUID { get }
    var productID: Int64 { get }
    var name: String { get }
    var price: String { get }
    // TODO:
    // An URL or String should be enough for the protocol and models
    // We can create the image from this once we're in the presentation layer
    var thumbnail: ProductImage? { get }
}

public protocol POSItemProvider {
    func providePointOfSaleItems() -> [POSItem]
}
