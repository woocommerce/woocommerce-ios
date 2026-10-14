import Networking

final class MockSubscriptionsRemote: SubscriptionsRemoteProtocol {
    var loadSubscriptionsResult: Result<[Subscription], Error> = .success([])
    private(set) var spyLoadSubscriptionsOrderIDs: [Int64] = []
    private(set) var loadSubscriptionCalled = false

    func loadSubscription(siteID: Int64, subscriptionID: Int64, completion: @escaping (Result<Subscription, Error>) -> Void) {
        loadSubscriptionCalled = true
        completion(.success(Subscription.fake()))
    }

    func loadSubscriptions(siteID: Int64, orderID: Int64, completion: @escaping (Result<[Subscription], Error>) -> Void) {
        spyLoadSubscriptionsOrderIDs.append(orderID)
        completion(loadSubscriptionsResult)
    }
}
