import Foundation
import Networking
import class WooFoundation.CurrencyFormatter

/// POSCartItem is different from the CartItem in the POS app layer.
/// - The POS cart UI might show the cart items differently from how they appear in an order in wp-admin.
public struct POSCartItem {
    let product: POSItem
    let quantity: Decimal

    public init(product: POSItem, quantity: Decimal) {
        self.product = product
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
    func sendOrderReceipt(order: Order, recipientEmail: String) async throws
}

public final class POSOrderService: POSOrderServiceProtocol {
    // MARK: - Properties

    private let siteID: Int64
    private let ordersRemote: POSOrdersRemoteProtocol
    private let receiptsRemote: POSReceiptsRemoteProtocol

    // MARK: - Initialization

    public convenience init?(siteID: Int64, credentials: Credentials?) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSOrderService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials)
        self.init(siteID: siteID,
                  ordersRemote: OrdersRemote(network: network),
                  receiptsRemote: ReceiptRemote(network: network))
    }

    public init(siteID: Int64, ordersRemote: POSOrdersRemoteProtocol, receiptsRemote: POSReceiptsRemoteProtocol) {
        self.siteID = siteID
        self.ordersRemote = ordersRemote
        self.receiptsRemote = receiptsRemote
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

    public func sendOrderReceipt(order: Order, recipientEmail: String) async throws {
        guard order.billingAddress?.email == nil || order.billingAddress?.email == "" else {
            throw POSOrderServiceError.emailAlreadySet
        }
        let updatedBillingAddress = order.billingAddress?.copy(email: recipientEmail)
        let updatedOrder = order.copy(billingAddress: updatedBillingAddress)

        let _ = try await ordersRemote.updatePOSOrder(siteID: siteID, order: updatedOrder, fields: [.billingAddress])
        try await receiptsRemote.sendPOSReceipt(siteID: siteID, orderID: order.orderID)
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
        let cartProducts = cart.map { POSOrderSyncProductType(productID: $0.product.productID,
                                                              price: $0.product.price,
                                                              productType: $0.product.productType) }

        // Removes all existing items by setting quantity to 0.
        let itemsToRemove = order.items.compactMap {
            Self.removalProductInput(item: $0)
        }

        // Adds items from the latest cart grouping cart items of the same product.
        let quantitiesByProductID = createQuantitiesByProductID(from: cart)
        let productIDsSortedByOrderInCart = quantitiesByProductID.keys.sorted { lhs, rhs in
            let lhsIndexInCart = cartProducts.firstIndex(where: { $0.productID == lhs }) ?? 0
            let rhsIndexInCart = cartProducts.firstIndex(where: { $0.productID == rhs }) ?? 0
            return lhsIndexInCart < rhsIndexInCart
        }
        let itemsToAdd: [OrderSyncProductInput] = productIDsSortedByOrderInCart.compactMap { productID in
            guard let quantity = quantitiesByProductID[productID],
                  let product = cartProducts.first(where: { $0.productID == productID }) else {
                return nil
            }
            return OrderSyncProductInput(product: .product(product), quantity: quantity)
        }
        let itemsToSync = itemsToRemove + itemsToAdd

        return ProductInputTransformer.updateMultipleItems(with: itemsToSync, on: order, shouldUpdateOrDeleteZeroQuantities: .update)
    }

    func createQuantitiesByProductID(from cart: [POSCartItem]) -> [Int64: Decimal] {
        cart.reduce([Int64: Decimal]()) { partialResult, cartItem in
            var result = partialResult
            if let quantity = partialResult[cartItem.product.productID] {
                result[cartItem.product.productID] = quantity + cartItem.quantity
            } else {
                result[cartItem.product.productID] = cartItem.quantity
            }
            return result
        }
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
    }
}
