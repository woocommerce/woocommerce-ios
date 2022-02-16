import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

class NewOrderInitialStatusResolverTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    func test_no_store_version_use_pending_status() {
        // Given
        let stores = createStoreWithVersion(nil)

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, stores: stores)
        let initialStatus: OrderStatusEnum = waitFor { promise in
            resolver.resolve { status in
                promise(status)
            }
        }

        // Then
        XCTAssertEqual(initialStatus, .pending)
    }

    func test_older_store_version_use_pending_status() {
        // Given
        let stores = createStoreWithVersion("6.2.5")

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, stores: stores)
        let initialStatus: OrderStatusEnum = waitFor { promise in
            resolver.resolve { status in
                promise(status)
            }
        }

        // Then
        XCTAssertEqual(initialStatus, .pending)
    }

    func test_same_store_version_use_draft_status() {
        // Given
        let stores = createStoreWithVersion("6.3.0")

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, stores: stores)
        let initialStatus: OrderStatusEnum = waitFor { promise in
            resolver.resolve { status in
                promise(status)
            }
        }

        // Then
        XCTAssertEqual(initialStatus, .autoDraft)
    }

    func test_newer_store_version_use_draft_status() {
        // Given
        let stores = createStoreWithVersion("6.4.0")

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, stores: stores)
        let initialStatus: OrderStatusEnum = waitFor { promise in
            resolver.resolve { status in
                promise(status)
            }
        }

        // Then
        XCTAssertEqual(initialStatus, .autoDraft)
    }

    func test_beta_store_version_use_draft_status() {
        // Given
        let stores = createStoreWithVersion("6.3.0-beta.1")

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, stores: stores)
        let initialStatus: OrderStatusEnum = waitFor { promise in
            resolver.resolve { status in
                promise(status)
            }
        }

        // Then
        XCTAssertEqual(initialStatus, .autoDraft)
    }
}

private extension NewOrderInitialStatusResolverTests {

    /// Creates a mock store manager that returns the provided version as part of the `SystemStatusAction.fetchSystemPlugin` action.
    ///
    func createStoreWithVersion(_ version: String?) -> StoresManager {
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                guard let version = version else {
                    return onCompletion(nil)
                }
                let plugin = SystemPlugin.fake().copy(version: version)
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action received: \(action)")
            }
        }
        return stores
    }
}
