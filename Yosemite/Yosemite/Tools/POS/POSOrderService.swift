import Foundation
import Networking

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

public struct POSOrder {
    public let siteID: Int64
    public let orderID: Int64
    public let total: String
    public let totalTax: String
    public let currency: String
    let items: [POSOrderItem]
}

public extension POSOrder {
    init(order: Order) {
        self.init(siteID: order.siteID,
                  orderID: order.orderID,
                  total: order.total,
                  totalTax: order.totalTax,
                  currency: order.currency,
                  items: order.items.map { POSOrderItem(orderItem: $0) })
    }
}

struct POSOrderItem {
    let itemID: Int64

    /// The product ID of a product order item, or the ID of the variable product if the order item is a product variation.
    let productID: Int64
    let quantity: Decimal

    func toOrderItem() -> OrderItem {
        .init(itemID: itemID,
              name: "",
              productID: productID,
              variationID: .zero,
              quantity: quantity,
              price: .zero,
              sku: nil,
              subtotal: "",
              subtotalTax: "",
              taxClass: "",
              taxes: [],
              total: "",
              totalTax: "",
              attributes: [],
              addOns: [],
              parent: nil,
              bundleConfiguration: [])
    }

    init(orderItem: OrderItem) {
        self.itemID = orderItem.itemID
        self.productID = orderItem.productID
        self.quantity = orderItem.quantity
    }
}

public protocol POSOrderServiceProtocol {
    /// Syncs order based on the cart.
    /// - Parameters:
    ///   - cart: Cart with optional items (product & quantity).
    ///   - order: Optional latest remotely synced order. Nil when syncing order for the first time.
    ///   - allProducts: Necessary for removing existing order items with products that have been removed from the cart.
    /// - Returns: Order from the remote sync.
    func syncOrder(cart: [POSCartItem], order: POSOrder?, allProducts: [POSItem]) async throws -> POSOrder

    /// Updates status of an order and syncs it
    /// - Parameters:
    ///   - posOrder: POS order.
    ///   - status: New order status.
    /// - Returns: Updated and synced POS order.
    func updateOrderStatus(posOrder: POSOrder, status: OrderStatusEnum) async throws -> POSOrder

    /// Creates WOO Order from POS Order.
    /// - Parameters:
    ///   - posOrder: POS order.
    /// - Returns: Order created from posOrder data.
    func order(from posOrder: POSOrder) -> Order
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

    public func syncOrder(cart: [POSCartItem], order posOrder: POSOrder?, allProducts: [POSItem]) async throws -> POSOrder {
        let initialOrder: Order = createInitialOrder(from: posOrder)

        let order = updateOrder(initialOrder, cart: cart, allProducts: allProducts)
        let syncedOrder: Order
        if posOrder != nil {
            syncedOrder = try await ordersRemote.updatePOSOrder(siteID: siteID, order: order, fields: [.items])
        } else {
            syncedOrder = try await ordersRemote.createPOSOrder(siteID: siteID, order: order, fields: [.items, .status])
        }

        return POSOrder(order: syncedOrder)
    }

    public func updateOrderStatus(posOrder: POSOrder, status: OrderStatusEnum) async throws -> POSOrder {
        let order: Order = order(from: posOrder)

        let syncedOrder: Order = try await ordersRemote.updatePOSOrder(siteID: siteID, order: order, fields: [.status])

        return POSOrder(order: syncedOrder)
    }

    public func order(from posOrder: POSOrder) -> Order {
        return OrderFactory.emptyNewOrder.copy(siteID: posOrder.siteID,
                                               orderID: posOrder.orderID,
                                               currency: posOrder.currency,
                                               total: posOrder.total,
                                               totalTax: posOrder.totalTax,
                                               items: posOrder.items.map { $0.toOrderItem() })
    }
}

private extension POSOrderService {
    func createInitialOrder(from posOrder: POSOrder?) -> Order {
        if let posOrder {
            return order(from: posOrder)
        }
        else {
            return OrderFactory.emptyNewOrder.copy(siteID: siteID, status: .autoDraft)
        }
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
