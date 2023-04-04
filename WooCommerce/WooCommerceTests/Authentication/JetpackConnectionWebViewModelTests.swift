import XCTest
import WordPressAuthenticator
@testable import WooCommerce

@MainActor
final class JetpackConnectionWebViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        WordPressAuthenticator.initializeAuthenticator()
    }

    func test_web_navigation_is_cancelled_upon_redirect_to_success_url() async throws {
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
        let adminURL = try XCTUnwrap(URL(string: siteURL + "/wp-admin"))
        let adminPolicy = await viewModel.decidePolicy(for: adminURL)
        let finalUrl = try XCTUnwrap(URL(string: "woocommerce://jetpack-connected"))
        let completionPolicy = await viewModel.decidePolicy(for: finalUrl)
        waitUntil {
            completionTriggered == true
        }

        // Then
        XCTAssertEqual(authorizePolicy, .allow)
        XCTAssertEqual(adminPolicy, .allow)
        XCTAssertEqual(completionPolicy, .cancel)
    }

    func test_web_navigation_is_cancelled_upon_redirect_to_plans_page() async throws {
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
        let finalUrl = try XCTUnwrap(URL(string: "https://wordpress.com/jetpack/connect/plans"))
        let completionPolicy = await viewModel.decidePolicy(for: finalUrl)
        waitUntil {
            completionTriggered == true
        }

        // Then
        XCTAssertEqual(authorizePolicy, .allow)
        XCTAssertEqual(completionPolicy, .cancel)
    }

    func test_dismissal_is_tracked_when_not_authenticated() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let siteURL = "https://test.com"
        let initialURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize/1/"))
        let viewModel = JetpackConnectionWebViewModel(initialURL: initialURL,
                                                      siteURL: siteURL,
                                                      stores: stores,
                                                      analytics: analytics,
                                                      completion: {})

        // When
        viewModel.handleDismissal()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_connect_dismissed" }))
    }

    func test_dismissal_is_not_tracked_when_authenticated() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let siteURL = "https://test.com"
        let initialURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize/1/"))
        let viewModel = JetpackConnectionWebViewModel(initialURL: initialURL,
                                                      siteURL: siteURL,
                                                      stores: stores,
                                                      analytics: analytics,
                                                      completion: {})

        // When
        viewModel.handleDismissal()

        // Then
        XCTAssertNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_connect_dismissed" }))
    }

    func test_completion_is_tracked_when_not_authenticated() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        var completionTriggered = false
        let completionHandler: () -> Void = {
            completionTriggered = true
        }

        let siteURL = "https://test.com"
        let initialURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize/1/"))
        let viewModel = JetpackConnectionWebViewModel(initialURL: initialURL,
                                                      siteURL: siteURL,
                                                      stores: stores,
                                                      analytics: analytics,
                                                      completion: completionHandler)

        // When
        let finalUrl = try XCTUnwrap(URL(string: "woocommerce://jetpack-connected"))
        _ = await viewModel.decidePolicy(for: finalUrl)
        waitUntil {
            completionTriggered == true
        }

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_connect_completed" }))
    }

    func test_completion_is_not_tracked_when_authenticated() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        var completionTriggered = false
        let completionHandler: () -> Void = {
            completionTriggered = true
        }

        let siteURL = "https://test.com"
        let initialURL = try XCTUnwrap(URL(string: "https://jetpack.wordpress.com/jetpack.authorize/1/"))
        let viewModel = JetpackConnectionWebViewModel(initialURL: initialURL,
                                                      siteURL: siteURL,
                                                      stores: stores,
                                                      analytics: analytics,
                                                      completion: completionHandler)

        // When
        let finalUrl = try XCTUnwrap(URL(string: "woocommerce://jetpack-connected"))
        _ = await viewModel.decidePolicy(for: finalUrl)
        waitUntil {
            completionTriggered == true
        }

        // Then
        XCTAssertNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_jetpack_connect_completed" }))
    }
}
