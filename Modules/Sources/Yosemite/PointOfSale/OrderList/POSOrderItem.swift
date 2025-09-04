import Foundation

public struct POSOrderItem: Equatable, Hashable {
    public let itemID: Int64
    public let name: String
    // periphery:ignore - Will be used for images
    public let productID: Int64
    // periphery:ignore - Will be used for images
    public let variationID: Int64
    public let quantity: Decimal
    public let formattedPrice: String
    public let formattedTotal: String
    public let imageSrc: String?
    public let attributes: [OrderItemAttribute]

    public init(itemID: Int64,
                name: String,
                productID: Int64,
                variationID: Int64,
                quantity: Decimal,
                formattedPrice: String,
                formattedTotal: String,
                imageSrc: String?,
                attributes: [OrderItemAttribute]) {
        self.itemID = itemID
        self.name = name
        self.productID = productID
        self.variationID = variationID
        self.quantity = quantity
        self.formattedPrice = formattedPrice
        self.formattedTotal = formattedTotal
        self.imageSrc = imageSrc
        self.attributes = attributes
    }
}
