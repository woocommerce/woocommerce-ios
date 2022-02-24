import Foundation
import Yosemite
import Combine

/// Type that syncs the order with the remote server.
///
final class RemoteOrderSynchronizer: OrderSynchronizer {

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

    /// This is the order status that we will use to keep the order in sync with the remote source.
    ///
    private var baseSyncStatus: OrderStatusEnum = .pending

    /// Subscriptions store.
    ///
    private var subscriptions = Set<AnyCancellable>()

    // MARK: Initializers

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores

        updateBaseSyncOrderStatus()
        bindInputs()
        bindOrderSync()
    }

    // MARK: Methods
    func retrySync() {
        // TODO: Implement
    }

    /// Creates the order remotely.
    ///
    func commitAllChanges(onCompletion: @escaping (Result<Order, Error>) -> Void) {
        // TODO: Implement
    }
}

// MARK: Helpers
private extension RemoteOrderSynchronizer {
    /// Updates the base sync order status.
    ///
    func updateBaseSyncOrderStatus() {
        NewOrderInitialStatusResolver(siteID: siteID, stores: stores).resolve { [weak self] baseStatus in
            self?.baseSyncStatus = baseStatus
        }
    }

    /// Updates the underlying order as inputs are received.
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
                order.copy(billingAddress: .some(addressesInput?.billing), shippingAddress: .some(addressesInput?.shipping))
            }
            .assign(to: &$order)

        setShipping.withLatestFrom(orderPublisher)
            .map { shippingLineInput, order in
                order.copy(shippingLines: shippingLineInput.flatMap { [$0] } ?? [])
            }
            .assign(to: &$order)
    }

    /// Creates the order(if needed) when a significant order input occurs.
    ///
    func bindOrderSync() {
        // Combine inputs that should trigger an order sync
        let syncTrigger: AnyPublisher<Void, Never> = setProduct.map { _ in () }
            .merge(with: setAddresses.map { _ in () })
            .merge(with: setShipping.map { _ in () })
            .merge(with: setFee.map { _ in () })
            .eraseToAnyPublisher()

        // Creates a "draft" order if the order has not been created yet.
        syncTrigger
            .debounce(for: 0.5, scheduler: DispatchQueue.main) // Group & wait for 0.5s since the last signal was emitted.
            .withLatestFrom(orderPublisher)
            .filter { _, order in
                order.orderID == .zero // Only continue if the order has not been created.
            }
            .flatMap(maxPublishers: .max(1)) { [weak self] (_, order) -> AnyPublisher<Order, Error> in // Only allow one request at a time.
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                self.state = .syncing
                return self.createOrderRemotely(order)
            }
            .catch { [weak self] error -> AnyPublisher<Order, Never> in // When an error occurs, update state & finish.
                self?.state = .error(error)
                return Empty().eraseToAnyPublisher()
            }
            .sink { [weak self] order in // When a value is received update state & order
                self?.state = .synced
                self?.order = order
            }
            .store(in: &subscriptions)
    }

    /// Returns a publisher that creates an order remotely using the `baseSyncStatus`.
    /// The later emitted order is delivered with the latest selected status.
    ///
    func createOrderRemotely(_ order: Order) -> AnyPublisher<Order, Error> {
        Future<Order, Error> { [weak self] promise in
            guard let self = self else { return }

            // Creates the order with the `draft` status
            let draftOrder = order.copy(status: self.baseSyncStatus)
            let action = OrderAction.createOrder(siteID: self.siteID, order: draftOrder) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let remoteOrder):
                    // Return the order with the current selected status.
                    let newLocalOrder = remoteOrder.copy(status: self.order.status)
                    promise(.success(newLocalOrder))

                case .failure(let error):
                    promise(.failure(error))
                }
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }
}
