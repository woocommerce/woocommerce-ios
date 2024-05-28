import Foundation
import Networking

public struct PointOfSaleCartProduct {
    public let productID: Int64
    public let price: String

    public init(productID: Int64, price: String) {
        self.productID = productID
        self.price = price
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
    public let items: [PointOfSaleOrderItem]
}

public struct PointOfSaleOrderItem {
    public let itemID: Int64

    /// The product ID of a product order item, or the ID of the variable product if the order item is a product variation.
    public let productID: Int64
    public let quantity: Decimal

    func toOrderItem() -> OrderItem {
        .init(itemID: itemID, name: "", productID: productID, variationID: .zero, quantity: quantity, price: .zero, sku: nil, subtotal: "", subtotalTax: "", taxClass: "", taxes: [], total: "", totalTax: "", attributes: [], addOns: [], parent: nil, bundleConfiguration: [])
    }

    init(orderItem: OrderItem) {
        self.itemID = orderItem.itemID
        self.productID = orderItem.productID
        self.quantity = orderItem.quantity
    }
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
        let initialOrder: Order = {
            if let posOrder {
                return OrderFactory.emptyNewOrder.copy(siteID: posOrder.siteID, orderID: posOrder.orderID, items: posOrder.items.map { $0.toOrderItem() })
            } else {
                // TODO: handle WC version under 6.3 when auto-draft status is unavailable as in `NewOrderInitialStatusResolver`
                return OrderFactory.emptyNewOrder.copy(siteID: siteID, status: .autoDraft)
            }
        }()
        let order = updateOrder(initialOrder, cart: cart)
        let syncedOrder: Order
        if posOrder != nil {
            syncedOrder = try await ordersRemote.updatePointOfSaleOrder(siteID: siteID, order: order, fields: [.items])
        } else {
            syncedOrder = try await ordersRemote.createPointOfSaleOrder(siteID: siteID, order: order, fields: [.items, .status])
        }
        return PointOfSaleOrder(siteID: syncedOrder.siteID,
                                orderID: syncedOrder.orderID,
                                total: syncedOrder.total,
                                totalTax: syncedOrder.totalTax,
                                items: syncedOrder.items.map { PointOfSaleOrderItem(orderItem: $0) })
    }
}

private struct PointOfSaleOrderSyncProductType: OrderSyncProductTypeProtocol {
    let productID: Int64
    let price: String
    // Not used in POS but have to be included for the app usage.
    let productType: ProductType
    let bundledItems: [ProductBundleItem]

    init(productID: Int64, price: String, productType: ProductType, bundledItems: [ProductBundleItem] = []) {
        self.productID = productID
        // TODO: price value only
        self.price = price.removingPrefix("$")
        self.productType = productType
        self.bundledItems = bundledItems
    }
}

private extension PointOfSaleOrderService {
    func updateOrder(_ order: Order, cart: [PointOfSaleCartItem]) -> Order {
        // We need to send all OrderSyncProductInput in one call to the RemoteOrderSynchronizer, both additions and deletions
        // otherwise may ignore the subsequent values that are sent
        let products: [PointOfSaleOrderSyncProductType] = cart.map { cartItem in
            // TODO: pass productType from product
            PointOfSaleOrderSyncProductType(productID: cartItem.product.productID, price: cartItem.product.price, productType: .simple)
        }
        var placeholderProductSelectorBundleConfigurationsByProductID: [Int64 : [[BundledProductConfiguration]]] = [:]
        let addedItemsToSync = ProductInputTransformer.productInputAdditionsToSync(orderItems: order.items, productsToSync: products, variations: [], productSelectorBundleConfigurationsByProductID: &placeholderProductSelectorBundleConfigurationsByProductID, allProducts: [], allProductVariations: [])
        let removedItemsToSync = ProductInputTransformer.productInputDeletionsToSync(orderItems: order.items, productsToSync: products, variations: [], allProducts: [], allProductVariations: [], defaultDiscount: { _ in 0 })
        let itemsToSync = addedItemsToSync + removedItemsToSync

        return ProductInputTransformer.updateMultipleItems(with: itemsToSync, on: order, shouldUpdateOrDeleteZeroQuantities: .update)
    }
}
