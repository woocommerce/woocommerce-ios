#if DEBUG
import protocol Yosemite.POSOrderServiceProtocol
import struct Yosemite.POSCartItem
import protocol Yosemite.POSItem
import enum Yosemite.OrderStatusEnum
import enum Yosemite.OrderFactory
import struct Yosemite.Order

class POSOrderPreviewService: POSOrderServiceProtocol {
    func syncOrder(cart: [POSCartItem], order: Order?) async throws -> Order {
        OrderFactory.emptyNewOrder
    }
}
#endif
