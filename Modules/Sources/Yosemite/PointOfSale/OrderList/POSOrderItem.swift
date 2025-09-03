import Foundation

public struct POSOrderItem: Equatable, Hashable {
    public let itemID: Int64
    public let name: String
    public let productID: Int64
    public let variationID: Int64
    public let quantity: Decimal
    public let price: NSDecimalNumber
    public let formattedPrice: String
    public let subtotal: String
    public let total: String
    public let formattedTotal: String
    public let attributes: [OrderItemAttribute]

    public init(itemID: Int64,
                name: String,
                productID: Int64,
                variationID: Int64,
                quantity: Decimal,
                price: NSDecimalNumber,
                formattedPrice: String,
                subtotal: String,
                total: String,
                formattedTotal: String,
                attributes: [OrderItemAttribute]) {
        self.itemID = itemID
        self.name = name
        self.productID = productID
        self.variationID = variationID
        self.quantity = quantity
        self.price = price
        self.formattedPrice = formattedPrice
        self.subtotal = subtotal
        self.total = total
        self.formattedTotal = formattedTotal
        self.attributes = attributes
    }
}
