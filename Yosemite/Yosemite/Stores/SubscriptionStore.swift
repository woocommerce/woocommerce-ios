import Foundation
import Storage
import Networking

/// Implements `SubscriptionAction` actions
///
public final class SubscriptionStore: Store {
    private let remote: SubscriptionsRemoteProtocol

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = SubscriptionsRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: SubscriptionsRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SubscriptionAction.self)
    }

    /// Receives and executes Actions.
    override public func onAction(_ action: Action) {
        guard let action = action as? SubscriptionAction else {
            assertionFailure("SubscriptionStore received an unsupported action")
            return
        }

        switch action {
        case .loadSubscriptions(let order, let completion):
            loadSubscriptions(for: order, completion: completion)
        }
    }
}

private extension SubscriptionStore {

    /// Retrieves all `Subscriptions` for a given `Order`.
    ///
    /// If the provided order is a subscription renewal order, we load the specific subscription using its ID.
    /// Otherwise, we load any subscriptions for the provided parent order.
    ///
    func loadSubscriptions(for order: Order, completion: @escaping (Result<[Subscription], Error>) -> Void) {
        if let subscriptionIDString = order.renewalSubscriptionID, let subscriptionID = Int64(subscriptionIDString) {
            remote.loadSubscription(siteID: order.siteID, subscriptionID: subscriptionID) { result in
                switch result {
                case .success(let response):
                    completion(.success([response]))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            remote.loadSubscriptions(siteID: order.siteID, orderID: order.orderID) { result in
                switch result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
