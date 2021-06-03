import XCTest
import WordPressKit

@testable import WooCommerce

/// Test cases for `AuthenticationManager`.
final class AuthenticationManagerTests: XCTestCase {
    /// We do not allow automatic WPCOM account sign-up if the user entered an email that is not
    /// registered in WordPress.com. This configuration is set up in
    /// `WordPressAuthenticatorConfiguration` in `AuthenticationManager.initialize()`.
    func test_it_supports_handling_for_unknown_WPCOM_user_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: WordPressComRestApiError.unknown.rawValue, userInfo: [
            WordPressComRestApi.ErrorKeyErrorCode: "unknown_user"
        ])

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    /// We provide a custom UI for sites that do not seem to be a WordPress site.
    func test_it_supports_handling_for_unknown_site_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: WordPressOrgXMLRPCValidatorError.invalid.rawValue)

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    /// We don't allow sites that do not have SSL. We provide a custom error UI for this.
    func test_it_supports_handling_for_non_SSL_site_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorSecureConnectionFailed)

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    func test_it_supports_handling_for_inaccessible_site_URL_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorCannotConnectToHost)

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }

    func test_it_supports_handling_for_unknown_site_URL_errors() {
        // Given
        let manager = AuthenticationManager()
        let error = NSError(domain: "", code: NSURLErrorCannotFindHost)

        // When
        let canHandle = manager.shouldHandleError(error)

        // Then
        XCTAssertTrue(canHandle)
    }
}
