public struct POSProduct: POSItem, Equatable {
    public let itemID: UUID
    public let productID: Int64
    public let name: String
    public let price: String
    public let formattedPrice: String
    public let itemCategories: [String]
    public var productImageSource: String?
    public let productType: ProductType

    public init(itemID: UUID,
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

    public static func ==(lhs: POSProduct, rhs: POSProduct) -> Bool {
        return lhs.itemID == rhs.itemID &&
        lhs.productID == rhs.productID &&
        lhs.name == rhs.name &&
        lhs.price == rhs.price &&
        lhs.formattedPrice == rhs.formattedPrice &&
        lhs.itemCategories == rhs.itemCategories &&
        lhs.productImageSource == rhs.productImageSource &&
        lhs.productType == rhs.productType
    }
}
