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

    func commitAllChanges(onCompletion: @escaping (Result<Order, Error>) -> Void) {
        let action = OrderAction.createOrder(siteID: siteID, order: order, onCompletion: onCompletion)
        stores.dispatch(action)
    }
}

private extension LocalOrderSynchronizer {
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
    }
}

private struct ProductInputTransformer {

    struct OrderItemParameters {
        let quantity: Decimal
        let price: Decimal
        let productID: Int64
        let variationID: Int64?
        var subtotal: String {
            "\(price * quantity)"
        }
    }

    static func update(input: OrderSyncProductInput, on order: Order) -> Order {
        guard input.quantity > 0 else {
            return remove(input: input, from: order)
        }

        let newItem = createOrderItem(using: input)
        var items = order.items
        if let itemIndex = order.items.firstIndex(where: { $0.itemID == newItem.itemID }) {
            items[itemIndex] = newItem
        } else {
            items.append(newItem)
        }

        return order.copy(items: items)
    }

    static func remove(input: OrderSyncProductInput, from order: Order) -> Order {
        var items = order.items
        items.removeAll { $0.itemID == input.id.hashValue }
        return order.copy(items: items)
    }

    static func createOrderItem(using input: OrderSyncProductInput) -> OrderItem {
        let quantity = Decimal(input.quantity)
        let parameters: OrderItemParameters = {
            switch input.product {
            case .product(let product):
                let price = Decimal(string: product.price) ?? .zero
                return OrderItemParameters(quantity: quantity, price: price, productID: product.productID, variationID: nil)
            case .variation(let variation):
                let price = Decimal(string: variation.price) ?? .zero
                return OrderItemParameters(quantity: quantity, price: price, productID: variation.productID, variationID: variation.productVariationID)
            }
        }()

        return OrderItem(itemID: Int64(input.id.hashValue),
                         name: "",
                         productID: parameters.productID,
                         variationID: parameters.variationID ?? 0,
                         quantity: quantity,
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
