import XCTest
import TestKit
import Fakes
@testable import Yosemite
@testable import Networking
@testable import Storage


/// UserStore Unit Tests
///
final class UserStoreTests: XCTestCase {
    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Testing SiteID
    ///
    private let testSiteID: Int64 = 123

    // MARK: Lifecycle

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: Tests

    func test_retrieveUser_returns_user_model_correctly() {
        // Given
        let urlSuffix = "sites/\(testSiteID)/users/me"
        network.simulateResponse(requestUrlSuffix: urlSuffix, filename: "user-complete")
        let store = UserStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<User, Error> = waitFor { promise in
            let action = UserAction.retrieveUser(siteID: self.testSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_retrieveUser_properly_returns_error() {
        // Given
        let store = UserStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<User, Error> = waitFor { promise in
            let action = UserAction.retrieveUser(siteID: self.testSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
