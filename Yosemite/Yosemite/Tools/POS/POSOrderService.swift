import Foundation
import Networking
import class WooFoundation.CurrencyFormatter

/// POSCartItem is different from the CartItem in the POS app layer.
/// - The POS cart UI might show the cart items differently from how they appear in an order in wp-admin.
public struct POSCartItem {
    /// Nil when the cart item is local and has not been synced remotely.
    let itemID: Int64?
    let product: POSItem
    let quantity: Decimal

    public init(itemID: Int64?, product: POSItem, quantity: Decimal) {
        self.itemID = itemID
        self.product = product
        self.quantity = quantity
    }
}

public protocol POSOrderServiceProtocol {
    /// Syncs order based on the cart.
    /// - Parameters:
    ///   - cart: Cart with optional items (product & quantity).
    ///   - order: Optional latest remotely synced order. Nil when syncing order for the first time.
    ///   - allProducts: Necessary for removing existing order items with products that have been removed from the cart.
    /// - Returns: Order from the remote sync.
    func syncOrder(cart: [POSCartItem], order: Order?, allProducts: [POSItem]) async throws -> Order
}

public final class POSOrderService: POSOrderServiceProtocol {
    // MARK: - Properties

    private let siteID: Int64
    private let ordersRemote: OrdersRemote

    // MARK: - Initialization

    public convenience init?(siteID: Int64, credentials: Credentials?) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSOrderService due to not finding credentials")
            return nil
        }
        self.init(siteID: siteID, network: AlamofireNetwork(credentials: credentials))
    }

    public init(siteID: Int64, network: Network) {
        self.siteID = siteID
        self.ordersRemote = OrdersRemote(network: network)
    }

    // MARK: - Protocol conformance

    public func syncOrder(cart: [POSCartItem], order posOrder: Order?, allProducts: [POSItem]) async throws -> Order {
        let initialOrder: Order = posOrder ?? OrderFactory.emptyNewOrder.copy(siteID: siteID, status: .autoDraft)
        let order = updateOrder(initialOrder, cart: cart, allProducts: allProducts).sanitizingLocalItems()
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
    func updateOrder(_ order: Order, cart: [POSCartItem], allProducts: [POSItem]) -> Order {
        let cartProducts = cart.map { POSOrderSyncProductType(productID: $0.product.productID,
                                                              price: $0.product.price,
                                                              productType: $0.product.productType) }
        let allProducts = allProducts.map { POSOrderSyncProductType(productID: $0.productID,
                                                                    price: $0.price,
                                                                    productType: $0.productType) }

        // Removes all existing items by setting quantity to 0.
        let itemsToRemove = order.items.compactMap {
            ProductInputTransformer.createUpdateProductInput(item: $0, quantity: 0, allProducts: allProducts, allProductVariations: [], defaultDiscount: 0)
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
                  let product = allProducts.first(where: { $0.productID == productID }) else {
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
}
