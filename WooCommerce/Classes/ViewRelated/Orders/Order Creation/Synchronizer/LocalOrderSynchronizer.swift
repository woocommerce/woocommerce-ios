import Foundation
import Yosemite
import Combine

/// Local implementation that does not syncs the order with the remote server.
///
final class LocalOrderSynchronizer: OrderSynchronizer {

    // MARK: Outputs

    @Published private(set) var state: OrderSyncState = .synced

    var statePublisher: Published<OrderSyncState>.Publisher {
        $state
    }

    @Published private(set) var order: Order = Order.empty

    var orderPublisher: Published<Order>.Publisher {
        $order
    }

    // MARK: Inputs

    var setStatus = PassthroughSubject<OrderStatusEnum, Never>()

    var setProduct = PassthroughSubject<OrderSyncProductInput, Never>()

    var setAddresses = PassthroughSubject<OrderSyncAddressesInput?, Never>()

    var setShipping =  PassthroughSubject<ShippingLine?, Never>()

    var setFee = PassthroughSubject<OrderFeeLine?, Never>()

    // MARK: Private properties

    private let siteID: Int64

    private let stores: StoresManager

    // MARK: Initializers

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
        bindInputs()
    }

    // MARK: Methods
    func retrySync() {
        // No op
    }

    /// Creates the order remotely.
    ///
    func commitAllChanges(onCompletion: @escaping (Result<Order, Error>) -> Void) {
        let action = OrderAction.createOrder(siteID: siteID, order: order, onCompletion: onCompletion)
        stores.dispatch(action)
    }
}

private extension LocalOrderSynchronizer {
    /// Updates order as inputs are received.
    ///
    func bindInputs() {
        setStatus.withLatestFrom(orderPublisher)
            .map { newStatus, order in
                order.copy(status: newStatus)
            }
            .assign(to: &$order)

        setProduct.withLatestFrom(orderPublisher)
            .map { productInput, order in
               ProductInputTransformer.update(input: productInput, on: order)
            }
            .assign(to: &$order)

        setAddresses.withLatestFrom(orderPublisher)
            .map { addressesInput, order in
                order.copy(billingAddress: addressesInput?.billing, shippingAddress: addressesInput?.shipping)
            }
            .assign(to: &$order)

        // TODO: Bind shipping & fees input
    }
}

/// Helper to updates an `order` given an `OrderSyncInput` type.
///
private struct ProductInputTransformer {
    /// Type to help bundling  order Items parameters.
    ///
    struct OrderItemParameters {
        let quantity: Decimal
        let price: Decimal
        let productID: Int64
        let variationID: Int64?
        var subtotal: String {
            "\(price * quantity)"
        }
    }

    /// Adds, deletes, or updates order items based on the given product input.
    ///
    static func update(input: OrderSyncProductInput, on order: Order) -> Order {
        // If the input's quantity is 0 or less, delete the item if possible.
        guard input.quantity > 0 else {
            return remove(input: input, from: order)
        }

        // Add or update the order items with the new input.
        let newItem = createOrderItem(using: input)
        var items = order.items
        if let itemIndex = order.items.firstIndex(where: { $0.itemID == newItem.itemID }) {
            items[itemIndex] = newItem
        } else {
            items.append(newItem)
        }

        return order.copy(items: items)
    }

    /// Removes an order item from an order when the `item.itemID` matches the `input.id`.
    ///
    private static func remove(input: OrderSyncProductInput, from order: Order) -> Order {
        var items = order.items
        items.removeAll { $0.itemID == input.id }
        return order.copy(items: items)
    }

    /// Creates and order item by using the `input.id` as the `item.itemID`.
    ///
    private static func createOrderItem(using input: OrderSyncProductInput) -> OrderItem {
        let parameters: OrderItemParameters = {
            switch input.product {
            case .product(let product):
                let price = Decimal(string: product.price) ?? .zero
                return OrderItemParameters(quantity: input.quantity, price: price, productID: product.productID, variationID: nil)
            case .variation(let variation):
                let price = Decimal(string: variation.price) ?? .zero
                return OrderItemParameters(quantity: input.quantity, price: price, productID: variation.productID, variationID: variation.productVariationID)
            }
        }()

        return OrderItem(itemID: input.id,
                         name: "",
                         productID: parameters.productID,
                         variationID: parameters.variationID ?? 0,
                         quantity: parameters.quantity,
                         price: parameters.price as NSDecimalNumber,
                         sku: nil,
                         subtotal: parameters.subtotal,
                         subtotalTax: "",
                         taxClass: "",
                         taxes: [],
                         total: "",
                         totalTax: "",
                         attributes: [])
    }
}
