import XCTest
@testable import WooCommerce

final class WPComEmailLoginViewModelTests: XCTestCase {

    func test_title_string_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, requiresConnectionOnly: false)

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComEmailLoginViewModel.Localization.installJetpack, text)
    }

    func test_title_string_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, requiresConnectionOnly: true)

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComEmailLoginViewModel.Localization.connectJetpack, text)
    }

    func test_subtitle_string_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, requiresConnectionOnly: false)

        // When
        let text = viewModel.subtitleString

        // Then
        assertEqual(WPComEmailLoginViewModel.Localization.loginToInstall, text)
    }

    func test_subtitle_string_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, requiresConnectionOnly: true)

        // When
        let text = viewModel.subtitleString

        // Then
        assertEqual(WPComEmailLoginViewModel.Localization.loginToConnect, text)
    }

    func test_terms_string_is_correct() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, requiresConnectionOnly: true)

        // When
        let text = viewModel.termsAttributedString.string

        // Then
        let expectedString = String(format: WPComEmailLoginViewModel.Localization.termsContent,
                                    WPComEmailLoginViewModel.Localization.termsOfService,
                                    WPComEmailLoginViewModel.Localization.shareDetails)
        assertEqual(text, expectedString)
    }

    func test_isEmailValid_is_false_for_invalid_email() {
        // Given
        let siteURL = "https://test.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, requiresConnectionOnly: true, debounceDuration: 0)

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
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, requiresConnectionOnly: true, debounceDuration: 0)

        // When
        viewModel.emailAddress = "random@mail.com"

        // Then
        waitUntil {
            viewModel.isEmailValid == true
        }
    }
}
