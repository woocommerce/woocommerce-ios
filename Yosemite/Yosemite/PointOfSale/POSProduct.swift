
struct POSProduct: POSItem {
    public let itemID: UUID
    public let productID: Int64
    public let name: String
    public let price: String
    public let thumbnail: ProductImage?

    init(itemID: UUID, productID: Int64, name: String, price: String, thumbnail: ProductImage?) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
        self.thumbnail = thumbnail
    }
}
