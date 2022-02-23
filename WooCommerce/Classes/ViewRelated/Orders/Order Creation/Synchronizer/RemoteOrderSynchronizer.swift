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

        setFee.withLatestFrom(orderPublisher)
            .map { feeLineInput, order in
                order.copy(fees: feeLineInput.flatMap { [$0] } ?? [])
            }
            .assign(to: &$order)
    }

    /// Creates or updates the order when a significant order input occurs.
    ///
    func bindOrderSync() {
        // Signal to force an order update.
        // Needed when the order creation finishes but the merchant issued new updates.
        let forceUpdateSignal = PassthroughSubject<SyncOperation, Never>()

        // Stores the latest request. Needed to validate if an update needs to be fired after the order is created.
        var latestRequest: SyncOperation?

        // Combine inputs that should trigger an order sync operation.
        let syncTrigger: AnyPublisher<SyncOperation, Never> = setProduct.map { _ in () }
            .merge(with: setAddresses.map { _ in () })
            .merge(with: setShipping.map { _ in () })
            .merge(with: setFee.map { _ in () })
            .debounce(for: 1, scheduler: DispatchQueue.main) // Group & wait for 0.5s since the last signal was emitted.
            .compactMap { [weak self] in
                guard let self = self else { return nil }
                print("Me: Sync Trigger")
                return SyncOperation(order: self.order) // Imperative `withLatestFrom` as it appears to have bugs when assigning a new order value.
            }
            .handleEvents(receiveOutput: { request in
                latestRequest = request // Assign latest request to further evaluation.
            })
            .share()
            .eraseToAnyPublisher()


        // Creates a "draft" order if the order has not been created yet.
        syncTrigger
            .filter { // Only continue if the order has not been created.
                $0.order.orderID == .zero
            }
            .flatMap(maxPublishers: .max(1)) { [weak self] request -> AnyPublisher<SyncOperation, Error> in // Only allow one request at a time.
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                self.state = .syncing
                print("Me: Creating Order")
                return self.createOrderRemotely(request)
            }
            .catch { [weak self] error -> AnyPublisher<SyncOperation, Never> in // When an error occurs, update state & finish.
                self?.state = .error(error)
                return Empty().eraseToAnyPublisher()
            }
            .sink { [weak self] response in
                // If there are no pending update requests, update state & order.
                if response.id == latestRequest?.id {
                    self?.state = .synced
                    self?.order = response.order
                    print("Me: Order Created")
                } else if let latestRequest = latestRequest {
                    // Otherwise update order id & force an update request.
                    let newOrderToUpdate = latestRequest.order.copy(orderID: response.order.orderID)
                    self?.order = newOrderToUpdate

                    forceUpdateSignal.send(SyncOperation(order: newOrderToUpdate))
                    print("Me: Order Created - Needs Update")
                }
            }
            .store(in: &subscriptions)


        // Updates a "draft" order after it has already been created.
        syncTrigger
            .merge(with: forceUpdateSignal)
            .filter { // Only continue if the order has been created.
                $0.order.orderID != .zero
            }
            .map { [weak self] request -> AnyPublisher<SyncOperation, Error> in // Allow multiple requests, once per update request.
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                self.state = .syncing
                print("Me: Updating Order")
                return self.updateOrderRemotely(request)
            }
            .switchToLatest() // Always switch/listen to the latest fired update request.
            .catch { [weak self] error -> AnyPublisher<SyncOperation, Never> in // When an error occurs, update state & finish.
                self?.state = .error(error)
                return Empty().eraseToAnyPublisher()
            }
            .sink { [weak self] response in // When finished, update state & order.
                self?.state = .synced
                self?.order = response.order
                print("Me: Order Updated")
            }
            .store(in: &subscriptions)
    }

    /// Returns a publisher that creates an order remotely using the `baseSyncStatus`.
    /// The later emitted order is delivered with the latest selected status.
    ///
    func createOrderRemotely(_ request: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        Future<SyncOperation, Error> { [weak self] promise in
            guard let self = self else { return }

            // Creates the order with the `draft` status
            let draftOrder = request.order.copy(status: self.baseSyncStatus)
            let action = OrderAction.createOrder(siteID: self.siteID, order: draftOrder) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let remoteOrder):
                    // Return the order with the current selected status.
                    let newLocalOrder = remoteOrder.copy(status: self.order.status)
                    let updatedRequest = request.copy(order: newLocalOrder)
                    promise(.success(updatedRequest))
                    print("Me: Create Request Ended")

                case .failure(let error):
                    promise(.failure(error))
                }
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }

    /// Returns a publisher that updates an order remotely.
    /// The later emitted order is delivered with the latest selected status.
    ///
    func updateOrderRemotely(_ request: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        Future<SyncOperation, Error> { [weak self] promise in
            guard let self = self else { return }

            // Updates the order supported fields.
            // Status is not updated as we want to continue using the "draft" status.
            let supportedFields: [OrderUpdateField] = [
                .shippingAddress,
                .billingAddress,
                .fees,
                .shippingLines,
            ]
            let action = OrderAction.updateOrder(siteID: self.siteID, order: request.order, fields: supportedFields) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let remoteOrder):
                    // Return the order with the current selected status.
                    let newLocalOrder = remoteOrder.copy(status: self.order.status)
                    let updatedRequest = request.copy(order: newLocalOrder)
                    promise(.success(updatedRequest))
                    print("Me: Update Request Ended")

                case .failure(let error):
                    promise(.failure(error))
                }
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: Definitions
private extension RemoteOrderSynchronizer {
    /// Type to represents a sync requests or a sync response.
    ///
    struct SyncOperation {
        /// Autogenerated ID of the operation.
        ///
        private(set) var id: String = UUID().uuidString

        /// Order to act upon.
        let order: Order

        /// Replaces the `order` maintaining the `ID`.
        ///
        func copy(order: Order) -> SyncOperation {
            SyncOperation(id: id, order: order)
        }
    }
}
