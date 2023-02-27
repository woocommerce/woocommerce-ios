import XCTest
@testable import WooCommerce

final class WPComEmailLoginViewModelTests: XCTestCase {

    func test_terms_string_is_correct() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL)

        // When
        let text = viewModel.termsAttributedString.string

        // Then
        let expectedString = String(format: Expectations.termsContent, Expectations.termsOfService, Expectations.shareDetails)
        assertEqual(text, expectedString)
    }

    func test_isEmailValid_is_false_for_invalid_email() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, debounceDuration: 0)

        // When
        viewModel.emailAddress = "random@mail."

        // Then
        waitUntil {
            viewModel.isEmailValid == false
        }
    }

    func test_isEmailValid_is_true_for_valid_email() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, debounceDuration: 0)

        // When
        viewModel.emailAddress = "random@mail.com"

        // Then
        waitUntil {
            viewModel.isEmailValid == true
        }
    }
}

private extension WPComEmailLoginViewModelTests {
    enum Expectations {
        static let termsContent = NSLocalizedString(
            "By tapping the Install Jetpack button, you agree to our %1$@ and to %2$@ with WordPress.com.",
            comment: "Content of the label at the end of the Wrong Account screen. " +
            "Reads like: By tapping the Connect Jetpack button, you agree to our Terms of Service and to share details with WordPress.com.")
        static let termsOfService = NSLocalizedString(
            "Terms of Service",
            comment: "The terms to be agreed upon when tapping the Connect Jetpack button on the Wrong Account screen."
        )
        static let shareDetails = NSLocalizedString(
            "share details",
            comment: "The action to be agreed upon when tapping the Connect Jetpack button on the Wrong Account screen."
        )
    }
}
