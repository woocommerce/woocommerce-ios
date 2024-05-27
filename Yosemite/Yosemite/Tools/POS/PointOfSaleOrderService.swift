import Foundation
import Networking

public struct PointOfSaleCartProduct {
    public let productID: Int64

    public init(productID: Int64) {
        self.productID = productID
    }
}

public struct PointOfSaleCartItem {
    /// Nil when the cart item is local and has not been synced remotely.
    public let itemID: Int64?
    public let product: PointOfSaleCartProduct
    public let quantity: Decimal

    public init(itemID: Int64?, product: PointOfSaleCartProduct, quantity: Decimal) {
        self.itemID = itemID
        self.product = product
        self.quantity = quantity
    }
}

public struct PointOfSaleOrder {
    public let siteID: Int64
    public let orderID: Int64
    public let total: String
    public let totalTax: String
}

public protocol PointOfSaleOrderServiceProtocol {
    func syncOrder(cart: [PointOfSaleCartItem], order: PointOfSaleOrder?) async throws -> PointOfSaleOrder
}

public final class PointOfSaleOrderService: PointOfSaleOrderServiceProtocol {
    // MARK: - Properties

    private let siteID: Int64
    private let ordersRemote: OrdersRemote

    // MARK: - Initialization

    public convenience init(siteID: Int64, credentials: Credentials) {
        self.init(siteID: siteID, network: AlamofireNetwork(credentials: credentials))
    }

    public init(siteID: Int64, network: Network) {
        self.siteID = siteID
        self.ordersRemote = OrdersRemote(network: network)
    }

    // MARK: - Protocol conformance

    public func syncOrder(cart: [PointOfSaleCartItem], order posOrder: PointOfSaleOrder?) async throws -> PointOfSaleOrder {
        let order: Order = {
            if let posOrder {

                return OrderFactory.emptyNewOrder.copy(siteID: posOrder.siteID)
            } else {
                // TODO: handle WC version under 6.3 when auto-draft status is unavailable as in `NewOrderInitialStatusResolver`
                return OrderFactory.emptyNewOrder.copy(siteID: siteID, status: .autoDraft)
            }
        }()
        let syncedOrder: Order
        if posOrder != nil {
            syncedOrder = try await ordersRemote.updatePointOfSaleOrder(siteID: siteID, order: order, fields: [.items])
        } else {
            syncedOrder = try await ordersRemote.createPointOfSaleOrder(siteID: siteID, order: order, fields: [.items, .status])
        }
        return PointOfSaleOrder(siteID: syncedOrder.siteID,
                                orderID: syncedOrder.orderID,
                                total: syncedOrder.total,
                                totalTax: syncedOrder.totalTax)
    }
}

private extension PointOfSaleOrderService {
//    func updateOrder(_ order: Order, cart: [PointOfSaleCartItem]) -> Order {
//        var updatedOrderItems = order.items
//
//        for cartItem in cart {
//            updateOrderItems(from: order, with: input, orderItems: &updatedOrderItems)
//        }
//
//        // If the input's quantity is 0 or less, delete the item if required.
//        // We perform a second loop for deletions so we don't attempt to access to overflown indexes
//        for input in inputs {
//            guard input.quantity > 0 || shouldUpdateOrDeleteZeroQuantities == .update else {
//                updatedOrderItems.removeAll(where: { $0.itemID == input.id })
//                return order.copy(items: updatedOrderItems)
//            }
//        }
//
//        return order.copy(items: updatedOrderItems)
//    }
//
//    /// Creates, or updates existing `OrderItems` of a given `Order` with any `OrderSyncProductInput` update
//    ///
//    /// - Parameters:
//    ///   - order: Represents an Order entity.
//    ///   - input: Types of products the synchronizer supports
//    ///   - updatedOrderItems: An array of `[OrderItem]` entities
//    ///
//    func updateOrderItems(from order: Order, with input: OrderSyncProductInput, orderItems updatedOrderItems: inout [OrderItem]) {
//        let newItem = createOrderItem(using: input)
//
//        if let itemIndex = order.items.firstIndex(where: { $0.itemID == input.id }) {
//            updatedOrderItems[itemIndex] = newItem
//        } else {
//            updatedOrderItems.append(newItem)
//        }
//    }
}
