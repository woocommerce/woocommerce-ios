
struct POSProduct: POSItem {
    let itemID: UUID
    let productID: Int64
    let name: String
    let price: String
    var productImageSource: String?

    init(itemID: UUID,
         productID: Int64,
         name: String,
         price: String,
         productImageSource: String?) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
        self.productImageSource = productImageSource
    }
}
