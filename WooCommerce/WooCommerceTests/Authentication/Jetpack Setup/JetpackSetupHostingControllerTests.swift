import Foundation
import XCTest

@testable import WooCommerce

/// Test cases for `JetpackSetupHostingController`.
///
final class JetpackSetupHostingControllerTests: XCTestCase {
    private let testURL = "https://test.com"

    func test_it_tracks_login_jetpack_setup_screen_viewed_when_view_loads_for_unauthenticated_users() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewController = JetpackSetupHostingController(siteURL: testURL,
                                                           connectionOnly: true,
                                                           stores: stores,
                                                           analytics: analytics,
                                                           onStoreNavigation: { _ in })

        // When
        _ = try XCTUnwrap(viewController.view)

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_screen_viewed" }))
    }

    func test_it_tracks_login_jetpack_setup_screen_dismissed_when_view_is_dismissed_for_unauthenticated_users() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewController = JetpackSetupHostingController(siteURL: testURL,
                                                           connectionOnly: true,
                                                           stores: stores,
                                                           analytics: analytics,
                                                           onStoreNavigation: { _ in })

        // When
        _ = try XCTUnwrap(viewController.view)
        let leftBarButtonItem = try XCTUnwrap(viewController.navigationItem.leftBarButtonItem)

        _ = leftBarButtonItem.target?.perform(leftBarButtonItem.action)
        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_setup_screen_dismissed" }))
    }
}
