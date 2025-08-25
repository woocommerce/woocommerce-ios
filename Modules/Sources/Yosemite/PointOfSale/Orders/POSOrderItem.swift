import Foundation
import struct NetworkingCore.OrderItem

public struct POSOrderItem: Equatable, Hashable {
    public let itemID: Int64
    public let name: String
    public let quantity: Decimal
    public let total: String
    public let sku: String?

    public init(itemID: Int64,
                name: String,
                quantity: Decimal,
                total: String,
                sku: String? = nil) {
        self.itemID = itemID
        self.name = name
        self.quantity = quantity
        self.total = total
        self.sku = sku
    }
}

// MARK: - Conversion from NetworkingCore.OrderItem
public extension POSOrderItem {
    init(from orderItem: OrderItem) {
        self.init(
            itemID: orderItem.itemID,
            name: orderItem.name,
            quantity: orderItem.quantity,
            total: orderItem.total,
            sku: orderItem.sku
        )
    }
}
