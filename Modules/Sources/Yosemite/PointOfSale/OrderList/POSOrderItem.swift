import Foundation

public struct POSOrderItem: Equatable, Hashable {
    public let itemID: Int64
    public let name: String
    public let quantity: Decimal
    public let price: Decimal
    public let total: Decimal
    public let totalTax: Decimal
    public let formattedPrice: String
    public let formattedTotal: String
    public let imageSrc: String?
    public let attributes: [OrderItemAttribute]

    public init(itemID: Int64,
                name: String,
                quantity: Decimal,
                price: Decimal,
                total: Decimal,
                totalTax: Decimal,
                formattedPrice: String,
                formattedTotal: String,
                imageSrc: String?,
                attributes: [OrderItemAttribute]) {
        self.itemID = itemID
        self.name = name
        self.quantity = quantity
        self.price = price
        self.total = total
        self.totalTax = totalTax
        self.formattedPrice = formattedPrice
        self.formattedTotal = formattedTotal
        self.imageSrc = imageSrc
        self.attributes = attributes
    }
}
