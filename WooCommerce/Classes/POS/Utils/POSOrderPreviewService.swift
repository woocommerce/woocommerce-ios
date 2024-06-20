#if DEBUG
import protocol Yosemite.POSOrderServiceProtocol
import struct Yosemite.POSCartItem
import struct Yosemite.POSOrder
import protocol Yosemite.POSItem
import enum Yosemite.OrderStatusEnum
import enum Yosemite.OrderFactory
import struct Yosemite.Order

class POSOrderPreviewService: POSOrderServiceProtocol {
    func syncOrder(cart: [POSCartItem], order: POSOrder?, allProducts: [any POSItem]) async throws -> POSOrder {
        if let order {
            return order
        }
        return POSOrder(order: OrderFactory.emptyNewOrder)
    }

    func updateOrderStatus(posOrder: POSOrder, status: OrderStatusEnum) async throws -> POSOrder {
        return posOrder
    }

    func order(from posOrder: POSOrder) -> Order {
        return OrderFactory.emptyNewOrder
    }
}
#endif
