import XCTest
@testable import WooCommerce

final class WPCom2FALoginViewModelTests: XCTestCase {

    func test_title_string_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let viewModel = WPCom2FALoginViewModel(requiresConnectionOnly: false)

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPCom2FALoginViewModel.Localization.installJetpack, text)
    }

    func test_title_string_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let viewModel = WPCom2FALoginViewModel(requiresConnectionOnly: true)

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPCom2FALoginViewModel.Localization.connectJetpack, text)
    }

}
