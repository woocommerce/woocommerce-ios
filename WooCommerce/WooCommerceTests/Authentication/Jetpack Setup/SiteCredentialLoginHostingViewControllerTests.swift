import Foundation
import XCTest
import WordPressAuthenticator

@testable import WooCommerce

/// Test cases for `SiteCredentialLoginHostingViewController`.
///
final class SiteCredentialLoginHostingViewControllerTests: XCTestCase {
    private let testURL = "https://test.com"

    override func setUp() {
        super.setUp()

        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        // There is no known tear down for the Authenticator. So this method intentionally does
        // nothing.
        super.tearDown()
    }

    func test_it_tracks_login_jetpack_site_credential_screen_viewed_when_view_loads() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewController = SiteCredentialLoginHostingViewController(siteURL: testURL, connectionOnly: true, analytics: analytics, onLoginSuccess: {})

        // When
        _ = try XCTUnwrap(viewController.view)

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_site_credential_screen_viewed" }))
    }

    func test_it_tracks_login_jetpack_site_credential_screen_dismissed_when_view_is_dismissed() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewController = SiteCredentialLoginHostingViewController(siteURL: testURL, connectionOnly: true, analytics: analytics, onLoginSuccess: {})

        // When
        _ = try XCTUnwrap(viewController.view)
        let leftBarButtonItem = try XCTUnwrap(viewController.navigationItem.leftBarButtonItem)

        _ = leftBarButtonItem.target?.perform(leftBarButtonItem.action)
        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_site_credential_screen_dismissed" }))
    }
}
