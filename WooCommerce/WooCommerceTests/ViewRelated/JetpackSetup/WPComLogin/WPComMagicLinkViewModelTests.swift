import XCTest
@testable import WooCommerce

final class WPComMagicLinkViewModelTests: XCTestCase {

    func test_instructionString_is_correct() {
        // Given
        let email = "test@example.com"
        let viewModel = WPComMagicLinkViewModel(email: email)

        // When
        let text = viewModel.instructionString.string

        // Then
        let expectedText = WPComMagicLinkViewModel.Localization.sentLink.replacingOccurrences(of: "%@", with: email)
        assertEqual(expectedText, text)
    }
}
