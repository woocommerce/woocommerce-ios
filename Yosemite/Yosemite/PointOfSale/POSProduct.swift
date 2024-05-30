
public struct POSProduct: POSItem {
    public let itemID: UUID
    public let productID: Int64
    public let name: String
    public let price: String
    public let formattedPrice: String

    public init(itemID: UUID, productID: Int64, name: String, price: String, formattedPrice: String) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
        self.formattedPrice = formattedPrice
    }
}
