import XCTest
@testable import WordPressAuthenticator
@testable import WooCommerce

final class WPComMagicLinkRequestViewModelTests: XCTestCase {
    func test_givenSuccessMagicLink_when_magicLinkRequested_then_onMagicLinkSent_called() async {
        // Given
        let mockAccountService = MockWordPressComAccountService()
        mockAccountService.authenticationLinkRequestError = nil

        var isMagicLinkSent = false
        let viewModel = WPComMagicLinkRequestViewModel(email: "email@example.com",
                                                       onMagicLinkSent: {_ in isMagicLinkSent = true },
                                                       onUseUsernamePassword: { },
                                                       onError: { _ in },
                                                       accountService: mockAccountService
        )

        // When
        await viewModel.sendMagicLink()

        // Then
        XCTAssertTrue(isMagicLinkSent)
    }

    func test_givenFailedMagicLink_when_magicLinkRequested_then_onError_called() async {
        // Given
        let mockAccountService = MockWordPressComAccountService()
        mockAccountService.authenticationLinkRequestError = NSError(domain: "Test", code: 401)

        var isErrorShown = false
        let viewModel = WPComMagicLinkRequestViewModel(email: "email@example.com",
                                                       onMagicLinkSent: {_ in },
                                                       onUseUsernamePassword: { },
                                                       onError: { _ in isErrorShown = true },
                                                       accountService: mockAccountService
        )

        // When
        await viewModel.sendMagicLink()

        // Then
        XCTAssertTrue(isErrorShown)
    }

    @MainActor func test_when_useUsernamePassword_called_then_handleCallback() {
        var isUsernamePasswordUsed = false
        let viewModel = WPComMagicLinkRequestViewModel(email: "email@example.com",
                                                       onMagicLinkSent: {_ in },
                                                       onUseUsernamePassword: { isUsernamePasswordUsed = true },
                                                       onError: { _ in }
        )

        // When
        viewModel.useUsernamePassword()

        // Then
        XCTAssertTrue(isUsernamePasswordUsed)
    }
}
