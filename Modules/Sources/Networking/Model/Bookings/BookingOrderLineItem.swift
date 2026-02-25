import Foundation

public struct BookingOrderLineItem: Hashable {
    public let itemID: Int64
    public let name: String
    public let productID: Int64
    public let variationID: Int64
    public let quantity: Decimal
    public let price: NSDecimalNumber
    public let subtotal: String
    public let total: String
    public let totalTax: String
    public let imageSrc: String?

    public init(itemID: Int64,
                name: String,
                productID: Int64,
                variationID: Int64,
                quantity: Decimal,
                price: NSDecimalNumber,
                subtotal: String,
                total: String,
                totalTax: String,
                imageSrc: String?) {
        self.itemID = itemID
        self.name = name
        self.productID = productID
        self.variationID = variationID
        self.quantity = quantity
        self.price = price
        self.subtotal = subtotal
        self.total = total
        self.totalTax = totalTax
        self.imageSrc = imageSrc
    }
}
