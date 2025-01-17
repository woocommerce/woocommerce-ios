import Foundation
import Networking
import class WooFoundation.CurrencyFormatter
import enum WooFoundation.CurrencyCode

/// POSCartItem is different from the CartItem in the POS app layer.
/// - The POS cart UI might show the cart items differently from how they appear in an order in wp-admin.
public struct POSCartItem {
    let item: POSOrderableItem
    let quantity: Decimal

    public init(item: POSOrderableItem, quantity: Decimal) {
        self.item = item
        self.quantity = quantity
    }
}

extension [POSCartItem] {
    public func matches(order: Order?) -> Bool {
        guard let order else {
            return self.isEmpty
        }

        let consolidatedCartItems = self.reduce(into: [POSCartItem]()) { partialResult, nextItem in
            if let matchingIndex = partialResult.firstIndex(where: { $0.item.isEqual(to: nextItem.item) }) {
                let itemToUpdate = partialResult[matchingIndex]
                partialResult[matchingIndex] = POSCartItem(item: itemToUpdate.item, quantity: itemToUpdate.quantity + nextItem.quantity)
            } else {
                partialResult.append(nextItem)
            }
        }

        let consolidatedOrderItems = order.items.reduce(into: [OrderItem]()) { partialResult, nextItem in
            if let matchingIndex = partialResult.firstIndex(where: { $0.productID == nextItem.productID && $0.variationID == nextItem.variationID }) {
                let itemToUpdate = partialResult[matchingIndex]
                partialResult[matchingIndex] = itemToUpdate.copy(quantity: itemToUpdate.quantity + nextItem.quantity)
            } else {
                partialResult.append(nextItem)
            }
        }

        guard consolidatedCartItems.count == consolidatedOrderItems.count else {
            return false
        }

        for cartItem in consolidatedCartItems {
            guard consolidatedOrderItems.contains(where: { orderItem in
                cartItem.item.matches(orderItem: orderItem) && cartItem.quantity == orderItem.quantity
            }) else {
                return false
            }
        }
        return true
    }

    func createGroupedOrderSyncProductInputs() -> [OrderSyncProductInput.ProductType: OrderSyncProductInput] {
        let orderSyncProductInputs = self.map { $0.item.toOrderSyncProductInput(quantity: $0.quantity) }

        // Group items by their `product`, which is actually a `ProductType` enum, representing a product or variation,
        // with an associated value for the underlying item.
        let groupedItems = Dictionary(grouping: orderSyncProductInputs, by: { $0.product })

        // Convert each group into a single `OrderSyncProductInput`
        let output = groupedItems.compactMapValues { items -> OrderSyncProductInput? in
            guard let firstItem = items.first else { return nil }

            // Aggregate the quantity for this item
            let totalQuantity = items.reduce(Decimal(0)) { $0 + $1.quantity }

            // Return a copy of the first item, with the aggregate quantity
            return OrderSyncProductInput(product: firstItem.product,
                                         quantity: totalQuantity,
                                         discount: firstItem.discount,
                                         baseSubtotal: firstItem.baseSubtotal,
                                         bundleConfiguration: firstItem.bundleConfiguration)
        }

        return output
    }
}

public protocol POSOrderServiceProtocol {
    /// Syncs order based on the cart.
    /// - Parameters:
    ///   - cart: Cart with optional items (product & quantity).
    ///   - order: Optional latest remotely synced order. Nil when syncing order for the first time.
    /// - Returns: Order from the remote sync.
    func syncOrder(cart: [POSCartItem], order: Order?, currency: CurrencyCode) async throws -> Order
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

    public func syncOrder(cart: [POSCartItem],
                          order posOrder: Order?,
                          currency: CurrencyCode) async throws -> Order {
        let initialOrder: Order = posOrder ?? OrderFactory.newOrder(currency: currency)
            .copy(siteID: siteID,
                  status: .autoDraft)
        let order = updateOrder(initialOrder, cart: cart).sanitizingLocalItems()
        let syncedOrder: Order
        if posOrder != nil {
            syncedOrder = try await ordersRemote.updatePOSOrder(siteID: siteID, order: order, fields: [.items])
        } else {
            syncedOrder = try await ordersRemote.createPOSOrder(siteID: siteID, order: order, fields: [.items, .status, .currency])
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
    func updateOrder(_ order: Order, cart: [POSCartItem]) -> Order {
        // Removes all existing items by setting quantity to 0.
        let itemsToRemove = order.items.compactMap {
            Self.removalProductInput(item: $0)
        }

        // Adds items from the latest cart grouping by item.
        let itemsToAdd = cart.createGroupedOrderSyncProductInputs().values
        let itemsToSync = itemsToRemove + itemsToAdd

        return ProductInputTransformer.updateMultipleItems(with: itemsToSync, on: order, shouldUpdateOrDeleteZeroQuantities: .update)
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
