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

        // Then
        XCTAssertEqual(authorizePolicy, .allow)
        XCTAssertEqual(completionPolicy, .cancel)
        XCTAssertTrue(completionTriggered)
    }

}
