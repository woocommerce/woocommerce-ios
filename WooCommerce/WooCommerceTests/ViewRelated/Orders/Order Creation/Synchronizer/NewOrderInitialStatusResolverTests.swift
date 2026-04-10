import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

@MainActor
class NewOrderInitialStatusResolverTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    func test_no_store_version_use_pending_status() {
        // Given
        let pluginsService = createPluginsServiceWithVersion(nil)

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, pluginsService: pluginsService)
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
        let pluginsService = createPluginsServiceWithVersion("6.2.5")

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, pluginsService: pluginsService)
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
        let pluginsService = createPluginsServiceWithVersion("6.3.0")

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, pluginsService: pluginsService)
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
        let pluginsService = createPluginsServiceWithVersion("6.4.0")

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, pluginsService: pluginsService)
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
        let pluginsService = createPluginsServiceWithVersion("6.3.0-beta.1")

        // When
        let resolver = NewOrderInitialStatusResolver(siteID: sampleSiteID, pluginsService: pluginsService)
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

    /// Creates a mock plugins service that returns the provided version.
    ///
    func createPluginsServiceWithVersion(_ version: String?) -> PluginsServiceProtocol {
        let mockService = MockPluginsService()
        if let version {
            let plugin = SystemPlugin.fake().copy(version: version)
            mockService.setMockPlugin(.wooCommerce, systemPlugin: plugin)
        } else {
            mockService.setMockPlugin(.wooCommerce, systemPlugin: nil)
        }
        return mockService
    }
}
