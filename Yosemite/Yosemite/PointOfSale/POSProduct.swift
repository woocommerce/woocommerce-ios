
struct POSProduct: POSItem {
    public let itemID: UUID
    public let productID: Int64
    public let name: String
    public let price: String

    init(itemID: UUID, productID: Int64, name: String, price: String) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
    }
}
