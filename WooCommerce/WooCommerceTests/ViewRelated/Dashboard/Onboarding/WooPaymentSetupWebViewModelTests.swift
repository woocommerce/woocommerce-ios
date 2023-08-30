import XCTest
@testable import WooCommerce

final class WooPaymentSetupWebViewModelTests: XCTestCase {

    func test_title_is_set_from_init() throws {
        // Given
        let viewModel = WooPaymentSetupWebViewModel(title: "Woo Test", initialURL: WooConstants.URLs.blog.asURL()) {}

        // Then
        XCTAssertEqual(viewModel.title, "Woo Test")
    }

    func test_initialURL_is_set_from_init() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let viewModel = WooPaymentSetupWebViewModel(initialURL: url) {}

        // Then
        XCTAssertEqual(viewModel.initialURL?.absoluteString, "https://woocommerce.com")
    }

    func test_redirecting_to_wpcom_invokes_reloadWebview() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let urlAfterWPComAuth = try XCTUnwrap(URL(string: WooPaymentSetupWebViewModel.Constants.urlAfterWPComAuth))
        let viewModel = WooPaymentSetupWebViewModel(initialURL: url) {}

        // When
        let urlToLoad: URL = waitFor { promise in
            viewModel.reloadWebview = {
                promise(url)
            }
            viewModel.handleRedirect(for: urlAfterWPComAuth)
        }

        // Then it loads the initial URL
        XCTAssertEqual(urlToLoad, url)
    }

    func test_redirecting_to_wpcom_does_not_invoke_reloadWebview_when_initialURL_is_the_same() throws {
        // Given
        let url = try XCTUnwrap(URL(string: WooPaymentSetupWebViewModel.Constants.urlAfterWPComAuth))
        let viewModel = WooPaymentSetupWebViewModel(initialURL: url) {}

        // When
        viewModel.reloadWebview = {
            // Then
            XCTFail("Unexpected webview load for \(url)")
        }
        viewModel.handleRedirect(for: url)
    }

    func test_redirecting_to_non_wpcom_does_not_invoke_reloadWebview() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let nonWPComAuthURL = try XCTUnwrap(URL(string: "https://example.com"))
        let viewModel = WooPaymentSetupWebViewModel(initialURL: url) {}

        // When
        viewModel.reloadWebview = {
            // Then
            XCTFail("Unexpected webview load for \(url)")
        }
        viewModel.handleRedirect(for: nonWPComAuthURL)
    }

    func test_redirecting_to_url_with_success_param_invokes_completion_handler() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let successURL = try XCTUnwrap(URL(string: "https://example.com?wcpay-connection-success=1"))
        var completionInvoked = false
        let viewModel = WooPaymentSetupWebViewModel(initialURL: url) {
            completionInvoked = true
        }

        // When
        viewModel.reloadWebview = {
            // Then
            XCTFail("Unexpected webview load for \(url)")
        }
        viewModel.handleRedirect(for: successURL)

        // Then
        XCTAssertTrue(completionInvoked)
    }

    func test_redirecting_to_url_with_error_param_invokes_completion_handler() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let errorURL = try XCTUnwrap(URL(string: "https://example.com?wcpay-connection-error=1"))
        var completionInvoked = false
        let viewModel = WooPaymentSetupWebViewModel(initialURL: url) {
            completionInvoked = true
        }

        // When
        viewModel.reloadWebview = {
            // Then
            XCTFail("Unexpected webview load for \(url)")
        }
        viewModel.handleRedirect(for: errorURL)

        // Then
        XCTAssertTrue(completionInvoked)
    }

    func test_redirecting_to_url_without_completion_param_does_not_invoke_completion_handler() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let nonCompletionURL = try XCTUnwrap(URL(string: "https://example.com"))
        var completionInvoked = false
        let viewModel = WooPaymentSetupWebViewModel(initialURL: url) {
            completionInvoked = true
        }

        // When
        viewModel.reloadWebview = {
            // Then
            XCTFail("Unexpected webview load for \(url)")
        }
        viewModel.handleRedirect(for: nonCompletionURL)

        // Then
        XCTAssertFalse(completionInvoked)
    }
}
