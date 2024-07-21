import Foundation
import Yosemite
import Combine
import WooFoundation

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

    @Published private(set) var giftCardToApply: String?

    var giftCardToApplyPublisher: Published<String?>.Publisher {
        $giftCardToApply
    }

    // MARK: Inputs

    var setStatus = PassthroughSubject<OrderStatusEnum, Never>()

    var setProduct = PassthroughSubject<OrderSyncProductInput, Never>()

    var setProducts = PassthroughSubject<[OrderSyncProductInput], Never>()

    var setAddresses = PassthroughSubject<OrderSyncAddressesInput?, Never>()

    var setShipping =  PassthroughSubject<ShippingLine, Never>()

    var removeShipping = PassthroughSubject<ShippingLine, Never>()

    var addFee = PassthroughSubject<OrderFeeLine, Never>()

    var removeFee = PassthroughSubject<OrderFeeLine, Never>()

    var updateFee = PassthroughSubject<OrderFeeLine, Never>()

    var addCoupon = PassthroughSubject<String, Never>()

    var removeCoupon = PassthroughSubject<String, Never>()

    let setGiftCard = PassthroughSubject<String?, Never>()

    var setNote = PassthroughSubject<String?, Never>()

    let setCustomerID = PassthroughSubject<Int64, Never>()

    let removeCustomerID = PassthroughSubject<Void, Never>()

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

    /// Triggers a remote sync after receiving a significant new input for the order.
    ///
    private var orderSyncTrigger = PassthroughSubject<Order, Never>()

    // MARK: Initializers

    init(siteID: Int64,
         flow: EditableOrderViewModel.Flow,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.stores = stores
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.blockingBehavior = .majorUpdates

        if case let .editing(initialOrder) = flow {
            order = initialOrder
        } else {
            updateBaseSyncOrderStatus()
        }

        bindInputs(flow: flow)
        bindOrderSync(flow: flow)
    }

    // MARK: Methods

    /// Commits all changes to the remote order.
    ///
    func commitAllChanges(onCompletion: @escaping (Result<Order, Error>, _ usesGiftCard: Bool) -> Void) {
        let usesGiftCard = giftCardToApply != nil
        Just(order)
            .flatMap { order -> AnyPublisher<Order, Error> in
                if order.orderID == .zero {
                    return self.createOrderRemotely(order, type: .commit, includesGiftCard: true) // Create order if it hasn't been created
                } else {
                    return self.updateOrderRemotely(order, type: .commit, includesGiftCard: true) // Update order if it has been created.
                }
            }
            .sink { finished in
                // We can let the whole chain fail because a new one is created in each `commitAllChanges` call.
                if case .failure(let error) = finished {
                    onCompletion(.failure(error), usesGiftCard)
                }
            } receiveValue: { order in
                onCompletion(.success(order), usesGiftCard)
            }
            .store(in: &subscriptions)
    }

    private var blockingBehavior: OrderSyncBlockBehavior
    func updateBlockingBehavior(_ behavior: OrderSyncBlockBehavior) {
        blockingBehavior = behavior
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

    /// Updates the underlying order as inputs are received, and triggers a remote sync for significant inputs.
    ///
    func bindInputs(flow: EditableOrderViewModel.Flow) {
        setStatus.withLatestFrom(orderPublisher)
            .map { newStatus, order in
                order.copy(status: newStatus)
            }
            .sink { [weak self] order in
                self?.order = order
                if case .editing = flow {
                    self?.orderSyncTrigger.send(order)
                }
            }
            .store(in: &subscriptions)

        setProduct.withLatestFrom(orderPublisher)
            .map { [weak self] productInput, order -> Order in
                guard let self = self else { return order }
                let localInput = self.replaceInputWithLocalIDIfNeeded(productInput)
                let updatedOrder = ProductInputTransformer.update(input: localInput, on: order, shouldUpdateOrDeleteZeroQuantities: .update)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        setProducts.withLatestFrom(orderPublisher)
            .map { [weak self] productsInput, order -> Order in
                guard let self = self else { return order }

                let localInputs = productsInput.map {
                    self.replaceInputWithLocalIDIfNeeded($0)
                }

                let updatedOrder = ProductInputTransformer.updateMultipleItems(
                    with: localInputs,
                    on: order,
                    shouldUpdateOrDeleteZeroQuantities: .update)

                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        setAddresses.withLatestFrom(orderPublisher)
            .map { addressesInput, order in
                order.copy(billingAddress: .some(addressesInput?.billing), shippingAddress: .some(addressesInput?.shipping))
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        setShipping.withLatestFrom(orderPublisher)
            .map { [weak self] shippingLineInput, order -> Order in
                guard let self = self else { return order }
                let updatedOrder = ShippingInputTransformer.update(input: shippingLineInput, on: order)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        removeShipping.withLatestFrom(orderPublisher)
            .map { [weak self] shippingLineInput, order -> Order in
                guard let self else { return order }
                let updatedOrder = ShippingInputTransformer.remove(input: shippingLineInput, from: order)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        addFee.withLatestFrom(orderPublisher)
            .map { [weak self] feeLineInput, order -> Order in
                guard let self = self else { return order }
                let updatedOrder = FeesInputTransformer.append(input: feeLineInput, on: order)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        updateFee.withLatestFrom(orderPublisher)
            .map { [weak self] feeLineInput, order -> Order in
                guard let self = self else { return order }
                let updatedOrder = FeesInputTransformer.update(input: feeLineInput, on: order)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        removeFee.withLatestFrom(orderPublisher)
            .map { [weak self] feeLineInput, order -> Order in
                guard let self = self else { return order }
                let updatedOrder = FeesInputTransformer.remove(input: feeLineInput, from: order)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        addCoupon.withLatestFrom(orderPublisher)
            .map { [weak self] couponLineInput, order -> Order in
                guard let self = self else { return order }
                let updatedOrder = CouponInputTransformer.append(input: couponLineInput, on: order)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)
        removeCoupon.withLatestFrom(orderPublisher)
            .map { [weak self] couponCode, order -> Order in
                guard let self = self else { return order }
                let updatedOrder = CouponInputTransformer.remove(code: couponCode, from: order)
                // Calculate order total locally while order is being synced
                return OrderTotalsCalculator(for: updatedOrder, using: self.currencyFormatter).updateOrderTotal()
            }
            .sink { [weak self] order in
                self?.order = order
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)

        setGiftCard.withLatestFrom(orderPublisher)
            .sink { [weak self] code, order in
                self?.giftCardToApply = code
                // Only syncs the order to apply the gift card right away in the editing flow.
                // In the creation flow, the gift card is applied when the user taps the Create CTA to create an order.
                if case .editing = flow {
                    self?.orderSyncTrigger.send(order)
                }
            }
            .store(in: &subscriptions)

        setNote.withLatestFrom(orderPublisher)
            .map { note, order in
                order.copy(customerNote: note)
            }
            .sink { [weak self] order in
                self?.order = order
                if case .editing = flow {
                    self?.orderSyncTrigger.send(order)
                }
            }
            .store(in: &subscriptions)

        setCustomerID.withLatestFrom(orderPublisher)
            .map { customerID, order in
                order.copy(customerID: customerID)
            }
            .sink { [weak self] order in
                self?.order = order
            }
            .store(in: &subscriptions)

        removeCustomerID.withLatestFrom(orderPublisher)
            .map { _, order in
                order.copy(customerID: 0)
            }
            .sink { [weak self] order in
                self?.order = order
            }
            .store(in: &subscriptions)

        retryTrigger.withLatestFrom(orderPublisher)
            .sink { [weak self] _, order in
                self?.orderSyncTrigger.send(order)
            }
            .store(in: &subscriptions)
    }

    /// Creates or updates the order when a significant order input occurs.
    ///
    func bindOrderSync(flow: EditableOrderViewModel.Flow) {
        let syncTrigger: AnyPublisher<Order, Never> = orderSyncTrigger
            .compactMap { [weak self] order in
                guard let self = self else { return nil }
                switch self.state {
                case .syncing(blocking: true):
                    return nil // Don't continue if the current state is `blocking`.
                default:
                    return order
                }
            }
            .share()
            .eraseToAnyPublisher()

        if flow == .creation {
            bindOrderCreation(trigger: syncTrigger)
        }
        bindOrderUpdate(trigger: syncTrigger, flow: flow)
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
                self.state = .syncing(blocking: true) // Creating an order is always a blocking operation

                return self.createOrderRemotely(order, type: .sync, includesGiftCard: false)
                    .catch { [weak self] error -> AnyPublisher<Order, Never> in // When an error occurs, update state & finish.
                        self?.state = .error(error, usesGiftCard: false)
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
    func bindOrderUpdate(trigger: AnyPublisher<Order, Never>, flow: EditableOrderViewModel.Flow) {
        // Updates a "draft" order after it has already been created.
        trigger
            .filter { // Only continue if the order has been created.
                $0.orderID != .zero
            }
            .handleEvents(receiveOutput: { [weak self] order in
                guard let self else { return }
                switch blockingBehavior {
                case .allUpdates:
                    // Always block when used in side-by-side mode because of immediate product change syncs and
                    // potential for inconsistent states
                    state = .syncing(blocking: true)
                case .majorUpdates:
                    // Set a `blocking` state if the order contains new lines or bundle configurations.
                    state = .syncing(blocking: order.containsLocalLines() || order.containsBundleConfigurations())
                }
            })
            .debounce(for: 1.0, scheduler: DispatchQueue.main) // Group & wait for 1.0 since the last signal was emitted.
            .map { [weak self] order -> AnyPublisher<Order, Never> in // Allow multiple requests, once per update request.
                guard let self = self else { return Empty().eraseToAnyPublisher() }

                let syncType: OperationType = flow == .creation ? .sync : .commit
                let includesGiftCard = flow != .creation
                let hasGiftCard = giftCardToApply != nil
                return self.updateOrderRemotely(order, type: syncType, includesGiftCard: includesGiftCard)
                    .catch { [weak self] error -> AnyPublisher<Order, Never> in // When an error occurs, update state & finish.
                        self?.state = .error(error, usesGiftCard: includesGiftCard && hasGiftCard)
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

    /// Returns a publisher that creates an order remotely, configured for the given operation type.
    /// The later emitted order is delivered with the latest selected status.
    ///
    func createOrderRemotely(_ order: Order, type: OperationType, includesGiftCard: Bool) -> AnyPublisher<Order, Error> {
        Future<Order, Error> { [weak self] promise in
            guard let self = self else { return }

            let giftCard = includesGiftCard ? self.giftCardToApply: nil

            let apiOrderStatus = self.orderStatus(for: type)
            let draftOrder = order.copy(status: apiOrderStatus).sanitizingLocalItems()
            let action = OrderAction.createOrder(siteID: self.siteID, order: draftOrder, giftCard: giftCard) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let remoteOrder):
                    if giftCard != nil {
                        self.giftCardToApply = nil
                    }
                    let newLocalOrder = self.updateOrderWithLocalState(targetOrder: remoteOrder, localOrder: self.order)
                    promise(.success(newLocalOrder))

                case .failure(let error):
                    promise(.failure(error))
                }
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }

    /// Returns a publisher that updates an order remotely, configured for the given operation type
    /// The later emitted order is delivered with the latest selected status.
    ///
    func updateOrderRemotely(_ order: Order, type: OperationType, includesGiftCard: Bool) -> AnyPublisher<Order, Error> {
        Future<Order, Error> { [weak self] promise in
            guard let self = self else { return }

            let operationUpdateFields = self.orderUpdateFields(for: type)
            let orderToSubmit = order.sanitizingLocalItems()
            let giftCard = includesGiftCard ? self.giftCardToApply: nil
            let action = OrderAction.updateOrder(siteID: self.siteID,
                                                 order: orderToSubmit,
                                                 giftCard: giftCard,
                                                 fields: operationUpdateFields) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let remoteOrder):
                    if giftCard != nil {
                        self.giftCardToApply = nil
                    }
                    let newLocalOrder = self.updateOrderWithLocalState(targetOrder: remoteOrder, localOrder: self.order)
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

    /// Defines the order status that should be sent to the remote API for a given operation type.
    ///
    func orderStatus(for type: OperationType) -> OrderStatusEnum {
        switch type {
        case .sync:
            return baseSyncStatus // When syncing always use the available draft status.
        case .commit:
            return order.status  // When committing changes always use the current order status.
        }
    }

    /// Defines the order update fields that should be sent to the remote API for a given operation type.
    ///
    func orderUpdateFields(for type: OperationType) -> [OrderUpdateField] {
        switch type {
        case .sync:  // We only sync addresses, items, fees, shipping and coupon lines.
            return [
                .shippingAddress,
                .billingAddress,
                .fees,
                .shippingLines,
                .couponLines,
                .items
            ]
        case .commit:
            return OrderUpdateField.allCases // When committing changes, we update everything.
        }
    }

    /// Return the targeted order with the current selected state.
    func updateOrderWithLocalState(targetOrder: Order, localOrder: Order) -> Order {
        targetOrder.copy(status: localOrder.status, customerNote: localOrder.customerNote)
    }
}

// MARK: Definitions
private extension RemoteOrderSynchronizer {
    /// Defines the types of operations the synchronizer performs.
    ///
    enum OperationType {
        /// Synching order operation type.
        ///
        case sync

        /// Committing order changes operation type.
        ///
        case commit
    }
}

// MARK: Order Helpers
private extension Order {
    /// Returns true if the order contains any local line (items, shipping, fees, or coupons).
    ///
    func containsLocalLines() -> Bool {
        let containsLocalLineItems = items.contains { LocalIDStore.isIDLocal($0.itemID) }
        let containsLocalShippingLines = shippingLines.contains { LocalIDStore.isIDLocal($0.shippingID) }
        let containsLocalFeeLines = fees.contains { LocalIDStore.isIDLocal($0.feeID) }
        let containsLocalCouponsLines = coupons.contains { LocalIDStore.isIDLocal($0.couponID) }
        return containsLocalLineItems || containsLocalShippingLines || containsLocalFeeLines || containsLocalCouponsLines
    }

    /// Returns true if the order contains any items with bundle configuration updates.
    ///
    func containsBundleConfigurations() -> Bool {
        items.map { $0.bundleConfiguration.isNotEmpty }.contains(true)
    }
}
