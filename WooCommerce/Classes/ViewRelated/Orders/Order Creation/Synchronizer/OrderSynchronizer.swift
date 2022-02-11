import Foundation
import Yosemite
import Combine

/// Possible states of an `OrderSynchronizer` type.
///
enum OrderSyncState {
    case syncing
    case synced
    case error(Error)
}

/// Product input for an `OrderSynchronizer` type.
///
struct OrderSyncProductInput {
    let product: Product
    let quantity: Int
}

/// Addresses input for an `OrderSynchronizer` type.
///
struct OrderSyncAddressesInput {
    let billing: Address
    let shipping: Address
}

/// A type that  receives "supported" order properties and keeps it synced against another source.
///
protocol OrderSynchronizer {

    // MARK: Outputs

    /// Defines the current sync state of the synchronizer.
    ///
    var state: Published<OrderSyncState> { get }

    /// Defines the latest order to be synced or that is synced.
    ///
    var order: Published<Order> { get }

    // MARK: Inputs

    /// Changes the underlaying order status.
    /// This property is not synched remotely until `commitAllChanges` method is invoked.
    ///
    var setStatus: PassthroughSubject<OrderStatusEnum, Never> { get }

    /// Sets a product with it's quantity.
    /// Set a `zero` quantity to remove a product.
    ///
    var setProduct: PassthroughSubject<OrderSyncProductInput, Never> { get }

    /// Sets or removes the order shipping & billing addresses.
    ///
    var setAddresses: PassthroughSubject<OrderSyncAddressesInput?, Never> { get }

    /// Sets or removes a shipping line.
    ///
    var setShipping: PassthroughSubject<ShippingLine?, Never> { get }

    /// Sets or removes an order fee.
    ///
    var setFee: PassthroughSubject<OrderFeeLine?, Never> { get }

    /// Retires the order sync. State needs to be in `.error` to initiate work.
    ///
    func retrySync()

    /// Commits all order changes to the remote source. State needs to be in `.synced` to initiate work.
    ///
    func commitAllChanges(onCompletion: (Result<Order, Error>) -> Void)
}
