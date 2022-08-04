import XCTest
@testable import WooCommerce

final class WooSetupWebViewModelTests: XCTestCase {

    func test_initial_url_is_correct() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WooSetupWebViewModel(siteURL: siteURL, onCompletion: {})

        // Then
        let expectedURL = "https://wordpress.com/plugins/woocommerce/test.com"
        XCTAssertEqual(viewModel.initialURL?.absoluteString, expectedURL)
    }

    func test_completion_handler_is_called_when_navigating_to_mobile_redirect() {
        // Given
        let siteURL = "https://test.com"
        var triggeredCompletion = false
        let completionHandler: () -> Void = {
            triggeredCompletion = true
        }
        let viewModel = WooSetupWebViewModel(siteURL: siteURL, onCompletion: completionHandler)

        // When
        let url = URL(string: "https://wordpress.com/marketplace/thank-you/woocommerce/")
        viewModel.handleRedirect(for: url)

        // Then
        XCTAssertTrue(triggeredCompletion)
    }

    func test_dismissal_is_tracked() throws {
        // Given
        let siteURL = "https://test.com"
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = WooSetupWebViewModel(siteURL: siteURL, analytics: analytics, onCompletion: {})

        // When
        viewModel.handleDismissal()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "login_woocommerce_setup_dismissed" }))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["source"] as? String, "web")
    }

    func test_completion_is_tracked() throws {
        // Given
        let siteURL = "https://test.com"
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = WooSetupWebViewModel(siteURL: siteURL, analytics: analytics, onCompletion: {})

        // When
        let url = URL(string: "https://wordpress.com/marketplace/thank-you/woocommerce/")
        viewModel.handleRedirect(for: url)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "login_woocommerce_setup_completed" }))
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(properties["source"] as? String, "web")
    }

    func test_dismissal_is_not_tracked_after_completion() throws {
        // Given
        let siteURL = "https://test.com"
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = WooSetupWebViewModel(siteURL: siteURL, analytics: analytics, onCompletion: {})

        // When
        let url = URL(string: "https://wordpress.com/marketplace/thank-you/woocommerce/")
        viewModel.handleRedirect(for: url)
        viewModel.handleDismissal()

        // Then
        XCTAssertNil(analyticsProvider.receivedEvents.first(where: { $0 == "login_woocommerce_setup_dismissed" }))
    }
}
