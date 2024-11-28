import Foundation
import Networking
import class WooFoundation.CurrencyFormatter

/// POSCartItem is different from the CartItem in the POS app layer.
/// - The POS cart UI might show the cart items differently from how they appear in an order in wp-admin.
public struct POSCartItem {
    let item: any POSOrderableItem
    let quantity: Decimal

    public init(item: any POSOrderableItem, quantity: Decimal) {
        self.item = item
        self.quantity = quantity
    }
}

public protocol POSOrderServiceProtocol {
    /// Syncs order based on the cart.
    /// - Parameters:
    ///   - cart: Cart with optional items (product & quantity).
    ///   - order: Optional latest remotely synced order. Nil when syncing order for the first time.
    /// - Returns: Order from the remote sync.
    func syncOrder(cart: [POSCartItem], order: Order?) async throws -> Order
}

public final class POSOrderService: POSOrderServiceProtocol {
    // MARK: - Properties

    private let siteID: Int64
    private let ordersRemote: POSOrdersRemoteProtocol

    // MARK: - Initialization

    public convenience init?(siteID: Int64, credentials: Credentials?) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSOrderService due to not finding credentials")
            return nil
        }
        self.init(siteID: siteID,
                  ordersRemote: OrdersRemote(network: AlamofireNetwork(credentials: credentials)))
    }

    public init(siteID: Int64, ordersRemote: POSOrdersRemoteProtocol) {
        self.siteID = siteID
        self.ordersRemote = ordersRemote
    }

    // MARK: - Protocol conformance

    public func syncOrder(cart: [POSCartItem], order posOrder: Order?) async throws -> Order {
        let initialOrder: Order = posOrder ?? OrderFactory.emptyNewOrder.copy(siteID: siteID, status: .autoDraft)
        let order = updateOrder(initialOrder, cart: cart).sanitizingLocalItems()
        let syncedOrder: Order
        if posOrder != nil {
            syncedOrder = try await ordersRemote.updatePOSOrder(siteID: siteID, order: order, fields: [.items])
        } else {
            syncedOrder = try await ordersRemote.createPOSOrder(siteID: siteID, order: order, fields: [.items, .status])
        }
        return syncedOrder
    }
}

private struct POSOrderSyncProductType: OrderSyncProductTypeProtocol {
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
        let itemsToAdd = createGroupedItemsToAdd(from: cart)
        let itemsToSync = itemsToRemove + itemsToAdd

        return ProductInputTransformer.updateMultipleItems(with: itemsToSync, on: order, shouldUpdateOrDeleteZeroQuantities: .update)
    }

    func createGroupedItemsToAdd(from cart: [POSCartItem]) -> [OrderSyncProductInput] {
        let orderSyncProductInputs = cart.map { $0.item.toOrderSyncProductInput(quantity: $0.quantity) }

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
        }.values

        return Array(output)
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
