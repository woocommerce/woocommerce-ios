import Foundation
import XCTest

@testable import WooCommerce
@testable import Yosemite

/// Test cases for `JetpackSetupHostingController`.
///
final class JetpackSetupHostingControllerTests: XCTestCase {
    private let testURL = "https://test.com"
    private let credentials = Credentials.wpcom(username: "test", authToken: "secret", siteAddress: "https://example.com")

    func test_it_tracks_login_jetpack_setup_screen_dismissed_when_view_is_dismissed_for_unauthenticated_users() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewController = JetpackSetupHostingController(siteURL: testURL,
                                                           siteID: 0,
                                                           connectionOnly: true,
                                                           wpcomCredentials: credentials,
                                                           stores: stores,
                                                           analytics: analytics,
                                                           onStoreNavigation: { _ in })

        // When
        _ = try XCTUnwrap(viewController.view)
        let leftBarButtonItem = try XCTUnwrap(viewController.navigationItem.leftBarButtonItem)

        _ = leftBarButtonItem.target?.perform(leftBarButtonItem.action)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "jetpack_setup_flow" }))
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["step"] as? String, "connection")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["connection_type"] as? String, "native")
        XCTAssertEqual(analyticsProvider.receivedProperties[indexOfEvent]["tap"] as? String, "dismiss")
    }
}
