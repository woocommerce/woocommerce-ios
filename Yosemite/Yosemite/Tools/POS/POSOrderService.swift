import Foundation
import Networking
import class WooFoundation.CurrencyFormatter
import enum WooFoundation.CurrencyCode

public protocol POSOrderServiceProtocol {
    /// Syncs order based on the cart.
    /// - Parameters:
    ///   - cart: Cart with different types of items and quantities.
    ///   - order: Optional latest remotely synced order. Nil when syncing order for the first time.
    /// - Returns: Order from the remote sync.
    func syncOrder(cart: POSCart, order: Order?, currency: CurrencyCode) async throws -> Order
    func updatePOSOrder(order: Order, recipientEmail: String) async throws
}

public final class POSOrderService: POSOrderServiceProtocol {
    private let siteID: Int64
    private let ordersRemote: POSOrdersRemoteProtocol

    public convenience init?(siteID: Int64, credentials: Credentials?) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSOrderService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials)
        self.init(siteID: siteID,
                  ordersRemote: OrdersRemote(network: network))
    }

    public init(siteID: Int64,
                ordersRemote: POSOrdersRemoteProtocol) {
        self.siteID = siteID
        self.ordersRemote = ordersRemote
    }

    // MARK: - Protocol conformance

    public func syncOrder(cart: POSCart,
                          order posOrder: Order?,
                          currency: CurrencyCode) async throws -> Order {
        let initialOrder: Order = posOrder ?? OrderFactory.newOrder(currency: currency)
            .copy(siteID: siteID,
                  status: .autoDraft)
        let order = updateOrder(initialOrder, cart: cart).sanitizingLocalItems()
        let syncedOrder: Order
        if posOrder != nil {
            syncedOrder = try await ordersRemote.updatePOSOrder(siteID: siteID, order: order, fields: [.items, .couponLines])
        } else {
            syncedOrder = try await ordersRemote.createPOSOrder(siteID: siteID, order: order, fields: [.items, .status, .currency, .couponLines])
        }
        return syncedOrder
    }

    public func updatePOSOrder(order: Order, recipientEmail: String) async throws {
        guard order.billingAddress?.email == nil || order.billingAddress?.email == "" else {
            throw POSOrderServiceError.emailAlreadySet
        }
        let updatedBillingAddress = order.billingAddress?.copy(email: recipientEmail)
        let updatedOrder = order.copy(billingAddress: updatedBillingAddress)

        do {
            let _ = try await ordersRemote.updatePOSOrder(siteID: siteID, order: updatedOrder, fields: [.billingAddress])
        } catch {
            throw POSOrderServiceError.updateOrderFailed
        }
    }
}

private struct POSOrderSyncProductType: OrderSyncProductTypeProtocol, Hashable {
    let productID: Int64
    let price: String
    // Not used in POS but have to be included for the app usage.
    let productType: ProductType
    let bundledItems: [ProductBundleItem]

    init(productID: Int64, price: String, productType: ProductType, bundledItems: [ProductBundleItem] = []) {
        self.productID = productID
        self.price = price
        self.productType = productType
        self.bundledItems = bundledItems
    }
}

private extension POSOrderService {
    func updateOrder(_ order: Order, cart: POSCart) -> Order {
        // Removes all existing items by setting quantity to 0.
        let itemsToRemove = order.items.compactMap {
            Self.removalProductInput(item: $0)
        }

        // Adds items from the latest cart grouping by item.
        let itemsToAdd = cart.items.createGroupedOrderSyncProductInputs().values
        let itemsToSync = itemsToRemove + itemsToAdd

        var order = ProductInputTransformer.updateMultipleItems(with: itemsToSync, on: order, shouldUpdateOrDeleteZeroQuantities: .update)
        order = updateCoupons(cart.coupons, on: order)

        return order
    }

    func updateCoupons(_ coupons: [POSCoupon], on order: Order) -> Order {
        // Get coupon codes from cart
        let cartCouponCodes = Set(coupons.map { $0.code })

        // Keep existing coupons that are still in the cart
        let remainingCoupons = order.coupons.filter { orderCoupon in
            cartCouponCodes.contains(orderCoupon.code)
        }

        // Find new coupons that need to be added (in cart but not in order)
        let existingCouponCodes = Set(order.coupons.map { $0.code })
        let newCoupons = coupons
            .filter { !existingCouponCodes.contains($0.code) }
            .map { OrderFactory.newOrderCouponLine(code: $0.code) }

        // Update order with remaining + new coupons
        return order.copy(coupons: remainingCoupons + newCoupons)
    }

    /// Creates a new `OrderSyncProductInput` type meant to remove an existing item from `OrderSynchronizer`
    ///
    static func removalProductInput(item: OrderItem) -> OrderSyncProductInput? {
        let productForRemoval = POSProductForRemoval(productID: item.productID)
        // Return a new input with the new quantity but with the same item id to properly reference the update.
        return OrderSyncProductInput(id: item.itemID,
                                     product: .product(productForRemoval),
                                     quantity: 0)
    }

    /// A simplified product struct, intended to contain only the `productID`
    struct POSProductForRemoval: OrderSyncProductTypeProtocol {
        var price: String = ""
        var productID: Int64
        var productType: ProductType = .simple
        var bundledItems: [ProductBundleItem] = []
    }
}

private extension POSOrderService {
    enum POSOrderServiceError: Error {
        case emailAlreadySet
        case updateOrderFailed
    }
}
