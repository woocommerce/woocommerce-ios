
struct POSProduct: POSItem {
    let itemID: UUID
    let productID: Int64
    let name: String
    let price: String
    let formattedPrice: String
    var productImageSource: String?

    init(itemID: UUID,
         productID: Int64,
         name: String,
         price: String,
         formattedPrice: String,
         productImageSource: String?) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
        self.formattedPrice = formattedPrice
        self.productImageSource = productImageSource
    }
}
