import XCTest
@testable import Networking
import Yosemite

final class SubscriptionStoreTests: XCTestCase {

    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage Manager
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network
    ///
    private var network: MockNetwork!

    /// Sample Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Sample Order ID
    ///
    private let sampleOrderID: Int64 = 12345

    /// Sample Subscription ID
    ///
    private let sampleSubscriptionID: Int64 = 282

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        storageManager = MockStorageManager()
        dispatcher = Dispatcher()
    }

    // MARK: - loadSubscriptions

    func test_loadSubscriptions_returns_specific_subscription_for_renewal_order_on_success() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "subscriptions/\(sampleSubscriptionID)", filename: "subscription")
        let store = SubscriptionStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let renewalOrder = Order.fake().copy(siteID: self.sampleSiteID, renewalSubscriptionID: "\(sampleSubscriptionID)")
        let result: Result<[Subscription], Error> = waitFor { promise in
            let action = SubscriptionAction.loadSubscriptions(for: renewalOrder) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let subscription = try XCTUnwrap(result.get().first)
        let expectedSubscription = Subscription(siteID: sampleSiteID,
                                                subscriptionID: sampleSubscriptionID,
                                                parentID: 281,
                                                status: .active,
                                                currency: "USD",
                                                billingPeriod: .week,
                                                billingInterval: "1",
                                                total: "14.50",
                                                startDate: DateFormatter.dateFromString(with: "2023-01-31T16:29:46"),
                                                endDate: DateFormatter.dateFromString(with: "2023-04-25T16:29:46"))
        assertEqual(expectedSubscription, subscription)
    }

    func test_loadSubscriptions_returns_errors_for_renewal_order_on_failure() {
        // Given
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "subscriptions/\(sampleSubscriptionID)", error: error)
        let store = SubscriptionStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let renewalOrder = Order.fake().copy(siteID: self.sampleSiteID, renewalSubscriptionID: "\(sampleSubscriptionID)")
        let result: Result<[Subscription], Error> = waitFor { promise in
            let action = SubscriptionAction.loadSubscriptions(for: renewalOrder) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

    func test_loadSubscriptions_returns_subscriptions_for_non_renewal_order_on_success() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "subscriptions", filename: "subscription-list")
        let store = SubscriptionStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<[Subscription], Error> = waitFor { promise in
            let action = SubscriptionAction.loadSubscriptions(for: Order.fake()) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let subscriptions = try XCTUnwrap(result.get())
        assertEqual(2, subscriptions.count)
    }

    func test_loadSubscriptions_returns_errors_for_non_renewal_order_on_failure() {
        // Given
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "subscriptions", error: error)
        let store = SubscriptionStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<[Subscription], Error> = waitFor { promise in
            let action = SubscriptionAction.loadSubscriptions(for: Order.fake()) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }

}
