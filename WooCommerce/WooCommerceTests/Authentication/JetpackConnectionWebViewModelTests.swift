import XCTest
@testable import WooCommerce

final class JetpackConnectionWebViewModelTests: XCTestCase {

    func test_completion_handler_returns_the_connected_email_from_url_query() async throws {
        // Given
        let siteURL = "https://test.com"
        var completionTriggered = false
        let completionHandler: () -> Void = {
            completionTriggered = true
        }
        let initialURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize/1/"))
        let viewModel = JetpackConnectionWebViewModel(initialURL: initialURL, siteURL: siteURL, completion: completionHandler)

        // When
        let authorizeURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize?user_email=test"))
        let authorizePolicy = await viewModel.decidePolicy(for: authorizeURL)
        let finalUrl = try XCTUnwrap(URL(string: siteURL + "/wp-admin"))
        let completionPolicy = await viewModel.decidePolicy(for: finalUrl)
        waitUntil {
            completionTriggered == true
        }

        // Then
        XCTAssertEqual(authorizePolicy, .allow)
        XCTAssertEqual(completionPolicy, .cancel)
    }

    func test_dismissal_is_tracked() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let siteURL = "https://test.com"
        let initialURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize/1/"))
        let viewModel = JetpackConnectionWebViewModel(initialURL: initialURL, siteURL: siteURL, analytics: analytics, completion: {})

        // When
        viewModel.handleDismissal()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_connect_dismissed" }))
    }

    func test_completion_is_tracked() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        var completionTriggered = false
        let completionHandler: () -> Void = {
            completionTriggered = true
        }

        let siteURL = "https://test.com"
        let initialURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize/1/"))
        let viewModel = JetpackConnectionWebViewModel(initialURL: initialURL, siteURL: siteURL, analytics: analytics, completion: completionHandler)

        // When
        let finalUrl = try XCTUnwrap(URL(string: siteURL + "/wp-admin"))
        _ = await viewModel.decidePolicy(for: finalUrl)
        waitUntil {
            completionTriggered == true
        }

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_connect_completed" }))
    }
}
