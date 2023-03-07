import XCTest
@testable import WooCommerce

final class WebCheckoutViewModelTests: XCTestCase {
    func test_initialURL_contains_site_slug() {
        // Given
        let siteSlug = "woo.com"

        // When
        let viewModel = WebCheckoutViewModel(siteSlug: siteSlug) {}

        // Then
        XCTAssertEqual(viewModel.initialURL?.absoluteString, "https://wordpress.com/checkout/woo.com")
    }

    func test_completion_is_only_invoked_once_when_handling_redirects_to_success_URL_multiple_times() throws {
        // Given
        let successURL = try XCTUnwrap(URL(string: "https://wordpress.com/checkout/thank-you/siteURL"))

        // When
        // A variable needs to exist outside of the `waitFor` closure, otherwise the instance is deallocated
        // when the async result returns.
        var viewModel: WebCheckoutViewModel?
        waitFor { promise in
            viewModel = WebCheckoutViewModel(siteSlug: "") {
                promise(())
            }
            viewModel?.handleRedirect(for: successURL)
            viewModel?.handleRedirect(for: successURL)
        }
    }
}
