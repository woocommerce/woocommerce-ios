import XCTest
@testable import WooCommerce

final class WPComPasswordLoginViewModelTests: XCTestCase {

    func test_title_string_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: "test@example.com",
                                                    requiresConnectionOnly: false,
                                                    onMultifactorCodeRequest: { _ in },
                                                    onLoginFailure: { _ in },
                                                    onLoginSuccess: { _ in })

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComPasswordLoginViewModel.Localization.installJetpack, text)
    }

    func test_title_string_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: "test@example.com",
                                                    requiresConnectionOnly: true,
                                                    onMultifactorCodeRequest: { _ in },
                                                    onLoginFailure: { _ in },
                                                    onLoginSuccess: { _ in })

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComPasswordLoginViewModel.Localization.connectJetpack, text)
    }

    func test_gravatar_url_is_correct() throws {
        // Given
        let siteURL = "https://example.com"
        let email = "test@example.com"
        let viewModel = WPComPasswordLoginViewModel(siteURL: siteURL,
                                                    email: email,
                                                    requiresConnectionOnly: true,
                                                    onMultifactorCodeRequest: { _ in },
                                                    onLoginFailure: { _ in },
                                                    onLoginSuccess: { _ in })

        // When
        let url = try XCTUnwrap(viewModel.avatarURL)

        // Then
        assertEqual("https://gravatar.com/avatar/55502f40dc8b7c769880b10874abc9d0?d=mp&s=80&r=g", url.absoluteString)
    }

}
