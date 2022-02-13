import Foundation
import Yosemite
import Combine

/// Local implementation that does not syncs the order with the remote server.
///
final class LocalOrderSynchronizer: OrderSynchronizer {

    @Published private(set) var state: OrderSyncState = .synced

    var statePublisher: Published<OrderSyncState>.Publisher {
        $state
    }

    @Published private(set) var order: Order = Order.empty

    var orderPublisher: Published<Order>.Publisher {
        $order
    }

    var setStatus = PassthroughSubject<OrderStatusEnum, Never>()

    var setProduct = PassthroughSubject<OrderSyncProductInput, Never>()

    var setAddresses = PassthroughSubject<OrderSyncAddressesInput?, Never>()

    var setShipping =  PassthroughSubject<ShippingLine?, Never>()

    var setFee = PassthroughSubject<OrderFeeLine?, Never>()

    func retrySync() {
    }

    func commitAllChanges(onCompletion: (Result<Order, Error>) -> Void) {
    }
}
