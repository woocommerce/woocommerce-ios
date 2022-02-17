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

    @Published private(set) var order: Order = OrderFactory.emptyNewOrder

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

        setShipping.withLatestFrom(orderPublisher)
            .map { shippingLineInput, order in
                order.copy(shippingLines: shippingLineInput.flatMap { [$0] } ?? [])
            }
            .assign(to: &$order)

        // TODO: Bind fees input
    }
}
