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

    private let currencyFormatter: CurrencyFormatter

    // MARK: Initializers

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.stores = stores
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
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
            .map { [weak self] productInput, order -> Order in
                guard let self = self else { return order }
                let sanitizedInput = self.replaceInputWithLocalIDIfNeeded(productInput)
                return ProductInputTransformer.update(input: sanitizedInput, on: order)
            }
            .map { [weak self] order in
                guard let self = self else { return order }
                return order.copy(total: self.getTotalFor(order))
            }
            .assign(to: &$order)

        setAddresses.withLatestFrom(orderPublisher)
            .map { addressesInput, order in
                order.copy(billingAddress: addressesInput?.billing, shippingAddress: addressesInput?.shipping)
            }
            .assign(to: &$order)

        setShipping.withLatestFrom(orderPublisher)
            .map { shippingLineInput, order in
                order.copy(shippingTotal: shippingLineInput?.total ?? "0", shippingLines: shippingLineInput.flatMap { [$0] } ?? [])
            }
            .map { [weak self] order in
                guard let self = self else { return order }
                return order.copy(total: self.getTotalFor(order))
            }
            .assign(to: &$order)

        setFee.withLatestFrom(orderPublisher)
            .map { feeLineInput, order in
                order.copy(fees: feeLineInput.flatMap { [$0] } ?? [])
            }
            .map { [weak self] order in
                guard let self = self else { return order }
                return order.copy(total: self.getTotalFor(order))
            }
            .assign(to: &$order)
    }

    /// Creates a new input with a random ID when the given ID is `.zero`.
    ///
    func replaceInputWithLocalIDIfNeeded(_ input: OrderSyncProductInput) -> OrderSyncProductInput {
        guard input.id == .zero else {
            return input
        }
        return input.updating(id: Int64(UUID().uuidString.hashValue))
    }

    /// Calculates and returns the current order total.
    ///
    func getTotalFor(_ order: Order) -> String {
        let itemsTotal = order.items
            .map { $0.subtotal }
            .compactMap { currencyFormatter.convertToDecimal(from: $0) }
            .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })

        let shippingTotal = currencyFormatter.convertToDecimal(from: order.shippingTotal) ?? .zero

        let feesTotal = order.fees
            .map { $0.total }
            .compactMap { currencyFormatter.convertToDecimal(from: $0) }
            .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })

        return itemsTotal.adding(shippingTotal).adding(feesTotal).stringValue
    }
}
