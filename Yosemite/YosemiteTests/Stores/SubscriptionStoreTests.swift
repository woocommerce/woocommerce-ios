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

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        storageManager = MockStorageManager()
        dispatcher = Dispatcher()
    }

    // MARK: - loadSubscriptions

    func test_loadSubscriptions_returns_subscriptions_on_success() throws {
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

    func test_loadSubscriptions_returns_errors_on_failure() {
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
