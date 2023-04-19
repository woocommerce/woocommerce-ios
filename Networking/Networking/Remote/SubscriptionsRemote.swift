import Foundation

/// Protocol for `SubscriptionsRemote` mainly used for mocking.
public protocol SubscriptionsRemoteProtocol {
    func loadSubscriptions(siteID: Int64,
                           orderID: Int64,
                           completion: @escaping (Result<[Subscription], Error>) -> Void)
}

/// Subscriptions: Remote Endpoints
///
public final class SubscriptionsRemote: Remote, SubscriptionsRemoteProtocol {

    /// Retrieves all `Subscriptions` for a parent `Order`.
    ///
    /// - Parameters:
    ///     - siteID: Remote ID of the site that owns the subscriptions.
    ///     - orderID: Remote ID of the parent order for the subscriptions.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadSubscriptions(siteID: Int64, orderID: Int64, completion: @escaping (Result<[Subscription], Error>) -> Void) {
        let parameters = [
            ParameterKey.parentOrder: orderID.description
        ]

        let path = Path.subscriptions
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = SubscriptionListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants
//
private extension SubscriptionsRemote {
    enum Path {
        static let subscriptions = "subscriptions"
    }

    enum ParameterKey {
        static let parentOrder = "parent"
    }
}
