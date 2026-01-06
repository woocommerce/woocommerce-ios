import Foundation

public struct POSOrderItem: Equatable, Hashable {
    public let itemID: Int64
    public let productID: Int64
    public let variationID: Int64
    public let name: String
    public let quantity: Decimal
    public let formattedPrice: String
    public let formattedTotal: String
    public let imageSrc: String?
    public let attributes: [OrderItemAttribute]

    public init(itemID: Int64,
                productID: Int64,
                variationID: Int64,
                name: String,
                quantity: Decimal,
                formattedPrice: String,
                formattedTotal: String,
                imageSrc: String?,
                attributes: [OrderItemAttribute]) {
        self.itemID = itemID
        self.productID = productID
        self.variationID = variationID
        self.name = name
        self.quantity = quantity
        self.formattedPrice = formattedPrice
        self.formattedTotal = formattedTotal
        self.imageSrc = imageSrc
        self.attributes = attributes
    }

    public var productOrVariationID: Int64 {
        variationID == 0 ? productID : variationID
    }
}
