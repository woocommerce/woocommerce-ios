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

    var retryTrigger = PassthroughSubject<Void, Never>()

    // MARK: Private properties

    private let siteID: Int64

    private let stores: StoresManager

    private let currencyFormatter: CurrencyFormatter

    /// This is the order status that we will use to keep the order in sync with the remote source.
    ///
    private var baseSyncStatus: OrderStatusEnum = .pending

    /// Subscriptions store.
    ///
    private var subscriptions = Set<AnyCancellable>()

    /// Store to serve local IDs.
    ///
    private let localIDStore = LocalIDStore()

    // MARK: Initializers

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.stores = stores
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        updateBaseSyncOrderStatus()
        bindInputs()
        bindOrderSync()
    }

    // MARK: Methods

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
            .map { [weak self] productInput, order in
                guard let self = self else { return order }
                let localInput = self.replaceInputWithLocalIDIfNeeded(productInput)
                let updatedOrder = ProductInputTransformer.update(input: localInput, on: order, updateZeroQuantities: true)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .assign(to: &$order)

        setAddresses.withLatestFrom(orderPublisher)
            .map { addressesInput, order in
                order.copy(billingAddress: .some(addressesInput?.billing), shippingAddress: .some(addressesInput?.shipping))
            }
            .assign(to: &$order)

        setShipping.withLatestFrom(orderPublisher)
            .map { [weak self] shippingLineInput, order in
                guard let self = self else { return order }
                let updatedOrder = ShippingInputTransformer.update(input: shippingLineInput, on: order)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .assign(to: &$order)

        setFee.withLatestFrom(orderPublisher)
            .map { [weak self] feeLineInput, order in
                guard let self = self else { return order }
                let updatedOrder = order.copy(fees: feeLineInput.flatMap { [$0] } ?? [])
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .assign(to: &$order)
    }

    /// Creates or updates the order when a significant order input occurs.
    ///
    func bindOrderSync() {
        // Combine inputs that should trigger an order sync operation.
        let syncTrigger: AnyPublisher<Order, Never> = setProduct.map { _ in () }
            .merge(with: setAddresses.map { _ in () })
            .merge(with: setShipping.map { _ in () })
            .merge(with: setFee.map { _ in () })
            .merge(with: retryTrigger.map { _ in () })
            .debounce(for: 0.5, scheduler: DispatchQueue.main) // Group & wait for 0.5 since the last signal was emitted.
            .compactMap { [weak self] in
                guard let self = self else { return nil }
                switch self.state {
                case .syncing(blocking: true):
                    return nil // Don't continue if the current state is `blocking`.
                default:
                    return self.order // Imperative `withLatestFrom` as it appears to have bugs when assigning a new order value.
                }
            }
            .share()
            .eraseToAnyPublisher()

        bindOrderCreation(trigger: syncTrigger)
        bindOrderUpdate(trigger: syncTrigger)
    }

    /// Binds the provided `trigger` and creates an order when needed(order does not exists remotely).
    ///
    func bindOrderCreation(trigger: AnyPublisher<Order, Never>) {
        // Creates a "draft" order if the order has not been created yet.
        trigger
            .filter { // Only continue if the order has not been created.
                $0.orderID == .zero
            }
            .flatMap(maxPublishers: .max(1)) { [weak self] order -> AnyPublisher<Order, Never> in // Only allow one request at a time.
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                self.state = .syncing(blocking: true) // Creating an oder is always a blocking operation

                return self.createOrderRemotely(order)
                    .catch { [weak self] error -> AnyPublisher<Order, Never> in // When an error occurs, update state & finish.
                        self?.state = .error(error)
                        return Empty().eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink { [weak self] order in
                self?.state = .synced
                self?.order = order
            }
            .store(in: &subscriptions)
    }

    /// Binds the provided `trigger` and updates an order when needed(order already exists remotely).
    ///
    func bindOrderUpdate(trigger: AnyPublisher<Order, Never>) {
        // Updates a "draft" order after it has already been created.
        trigger
            .filter { // Only continue if the order has been created.
                $0.orderID != .zero
            }
            .map { [weak self] order -> AnyPublisher<Order, Never> in // Allow multiple requests, once per update request.
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                self.state = .syncing(blocking: order.containsLocalLines()) // Set a `blocking` state if the order contains new lines
                return self.updateOrderRemotely(order)
                    .catch { [weak self] error -> AnyPublisher<Order, Never> in // When an error occurs, update state & finish.
                        self?.state = .error(error)
                        return Empty().eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest() // Always switch/listen to the latest fired update request.
            .sink { [weak self] order in // When finished, update state & order.
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
            let draftOrder = order.copy(status: self.baseSyncStatus).sanitizingLocalItems()
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

    /// Returns a publisher that updates an order remotely.
    /// The later emitted order is delivered with the latest selected status.
    ///
    func updateOrderRemotely(_ order: Order) -> AnyPublisher<Order, Error> {
        Future<Order, Error> { [weak self] promise in
            guard let self = self else { return }

            // Updates the order supported fields.
            // Status is not updated as we want to continue using the "draft" status.
            let supportedFields: [OrderUpdateField] = [
                .shippingAddress,
                .billingAddress,
                .fees,
                .shippingLines,
                .items,
            ]

            let orderToSubmit = order.sanitizingLocalItems()
            let action = OrderAction.updateOrder(siteID: self.siteID, order: orderToSubmit, fields: supportedFields) { [weak self] result in
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

    /// Creates a new input with a proper local ID when the provided input  ID is `.zero`.
    ///
    func replaceInputWithLocalIDIfNeeded(_ input: OrderSyncProductInput) -> OrderSyncProductInput {
        guard input.id == .zero else {
            return input
        }
        return input.updating(id: localIDStore.dispatchLocalID())
    }
}

// MARK: Definitions
private extension RemoteOrderSynchronizer {
    /// Simple type to serve negative IDs.
    /// This is needed to differentiate if an item ID has been synced remotely while providing a unique ID to consumers.
    /// If the ID is a negative number we assume that it's a local ID.
    /// Warning: This is not thread safe.
    ///
    final class LocalIDStore {
        /// Last used ID
        ///
        private var currentID: Int64 = 0

        /// Returns true if a given ID is deemed to be local(zero or negative).
        ///
        static func isIDLocal(_ id: Int64) -> Bool {
            id <= 0
        }

        /// Creates a new and unique local ID for this session.
        ///
        func dispatchLocalID() -> Int64 {
            currentID -= 1
            return currentID
        }
    }
}

// MARK: Order Helpers
private extension Order {
    /// Returns true if the order contains any local line (items, shipping, or fees).
    ///
    func containsLocalLines() -> Bool {
        let containsLocalLineItems = items.contains { RemoteOrderSynchronizer.LocalIDStore.isIDLocal($0.itemID) }
        let containsLocalShippingLines = shippingLines.contains { RemoteOrderSynchronizer.LocalIDStore.isIDLocal($0.shippingID) }
        let containsLocalFeeLines = fees.contains { RemoteOrderSynchronizer.LocalIDStore.isIDLocal($0.feeID) }
        return containsLocalLineItems || containsLocalShippingLines || containsLocalFeeLines
    }

    /// Removes the `itemID`, `total` & `subtotal` values from local items.
    /// This is needed to:
    /// 1. Create the item without the local ID, the remote API would fail otherwise.
    /// 2. Let the remote source calculate the correct item price & total as it can vary depending on the store configuration. EG: `prices_include_tax` is set.
    ///
    func sanitizingLocalItems() -> Order {
        let sanitizedItems: [OrderItem] = items.map { item in
            guard RemoteOrderSynchronizer.LocalIDStore.isIDLocal(item.itemID) else {
                return item
            }
            return item.copy(itemID: .zero, subtotal: "", total: "")
        }
        return copy(items: sanitizedItems)
    }
}
