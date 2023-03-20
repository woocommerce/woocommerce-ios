import XCTest
@testable import WooCommerce

final class WPAdminWebViewModelTests: XCTestCase {
    func test_title_is_set_from_init() throws {
        // Given
        let viewModel = WPAdminWebViewModel(title: "Woo Test", initialURL: WooConstants.URLs.blog.asURL())

        // Then
        XCTAssertEqual(viewModel.title, "Woo Test")
    }

    func test_initialURL_is_set_from_init() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let viewModel = WPAdminWebViewModel(initialURL: url)

        // Then
        XCTAssertEqual(viewModel.initialURL?.absoluteString, "https://woocommerce.com")
    }

    func test_redirecting_to_wpcom_invokes_loadWebview_for_initialURL() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let urlAfterWPComAuth = try XCTUnwrap(URL(string: URLs.urlAfterWPComAuth))
        let viewModel = WPAdminWebViewModel(initialURL: url)

        // When
        let urlToLoad: URL = waitFor { promise in
            viewModel.loadWebview = { url in
                promise(url)
            }
            viewModel.handleRedirect(for: urlAfterWPComAuth)
        }

        // Then it loads the initial URL
        XCTAssertEqual(urlToLoad, url)
    }

    func test_redirecting_to_wpcom_does_not_invoke_loadWebview_when_initialURL_is_the_same() throws {
        // Given
        let url = try XCTUnwrap(URL(string: URLs.urlAfterWPComAuth))
        let viewModel = WPAdminWebViewModel(initialURL: url)

        // When
        viewModel.loadWebview = { url in
            // Then
            XCTFail("Unexpected webview load for \(url)")
        }
        viewModel.handleRedirect(for: url)
    }

    func test_redirecting_to_non_wpcom_does_not_invoke_loadWebview() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://woocommerce.com"))
        let nonWPComAuthURL = try XCTUnwrap(URL(string: "https://example.com"))
        let viewModel = WPAdminWebViewModel(initialURL: url)

        // When
        viewModel.loadWebview = { url in
            // Then
            XCTFail("Unexpected webview load for \(url)")
        }
        viewModel.handleRedirect(for: nonWPComAuthURL)
    }
}

private extension WPAdminWebViewModelTests {
    enum URLs {
        static let urlAfterWPComAuth = "https://wordpress.com"
    }
}
