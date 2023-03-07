import XCTest
@testable import WooCommerce

final class WPComMagicLinkViewModelTests: XCTestCase {

    func test_titleString_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let viewModel = WPComMagicLinkViewModel(email: "test@example.com", requiresConnectionOnly: false)

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComMagicLinkViewModel.Localization.installJetpack, text)
    }

    func test_titleString_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let viewModel = WPComMagicLinkViewModel(email: "test@example.com", requiresConnectionOnly: true)

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComMagicLinkViewModel.Localization.connectJetpack, text)
    }

    func test_instructionString_is_correct() {
        // Given
        let email = "test@example.com"
        let viewModel = WPComMagicLinkViewModel(email: email, requiresConnectionOnly: true)

        // When
        let text = viewModel.instructionString.string

        // Then
        let expectedText = WPComMagicLinkViewModel.Localization.sentLink.replacingOccurrences(of: "%@", with: email)
        assertEqual(expectedText, text)
    }
}
