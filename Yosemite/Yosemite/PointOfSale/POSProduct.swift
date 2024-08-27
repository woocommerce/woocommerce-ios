struct POSProduct: POSItem {
    let itemID: UUID
    let productID: Int64
    let name: String
    let price: String
    let formattedPrice: String
    let itemCategories: [String]
    var productImageSource: String?
    let productType: ProductType

    init(itemID: UUID,
         productID: Int64,
         name: String,
         price: String,
         formattedPrice: String,
         itemCategories: [String],
         productImageSource: String?,
         productType: ProductType) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
        self.formattedPrice = formattedPrice
        self.itemCategories = itemCategories
        self.productImageSource = productImageSource
        self.productType = productType
    }
}
