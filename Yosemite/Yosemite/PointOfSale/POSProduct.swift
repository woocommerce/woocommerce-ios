
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

// TODO:
// Temporary implementation just to comply with `POSItem` conformance
extension POSProduct {
    public var imageURL: URL {
        let imageURLString = "http://www.automattic.com"
        return URL(string: imageURLString)!
    }

    public var details: [String] {
        return [""]
    }

    public func makeCartItem() -> CartItem {
        fatalError("Not implemented")
    }
}
