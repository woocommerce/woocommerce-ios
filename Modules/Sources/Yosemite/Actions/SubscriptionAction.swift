import Foundation

public enum SubscriptionAction: Action {

    /// Retrieves all Subscriptions for a given Order.
    ///
    case loadSubscriptions(for: Order, completion: (Result<[Subscription], Error>) -> Void)
}
