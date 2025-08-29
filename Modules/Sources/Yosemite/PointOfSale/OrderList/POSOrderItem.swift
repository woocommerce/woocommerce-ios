import Foundation
import struct NetworkingCore.OrderItem
import struct NetworkingCore.OrderItemAttribute

public struct POSOrderItem: Equatable, Hashable {
    public let itemID: Int64
    public let name: String
    public let productID: Int64
    public let variationID: Int64
    public let quantity: Decimal
    public let price: NSDecimalNumber
    public let subtotal: String
    public let total: String
    public let attributes: [OrderItemAttribute]

    public init(itemID: Int64,
                name: String,
                productID: Int64,
                variationID: Int64,
                quantity: Decimal,
                price: NSDecimalNumber,
                subtotal: String,
                total: String,
                attributes: [OrderItemAttribute]) {
        self.itemID = itemID
        self.name = name
        self.productID = productID
        self.variationID = variationID
        self.quantity = quantity
        self.price = price
        self.subtotal = subtotal
        self.total = total
        self.attributes = attributes
    }
}

// MARK: - Conversion from NetworkingCore.OrderItem
public extension POSOrderItem {
    init(from orderItem: OrderItem) {
        self.init(
            itemID: orderItem.itemID,
            name: orderItem.name,
            productID: orderItem.productID,
            variationID: orderItem.variationID,
            quantity: orderItem.quantity,
            price: orderItem.price,
            subtotal: orderItem.subtotal,
            total: orderItem.total,
            attributes: orderItem.attributes
        )
    }
}
