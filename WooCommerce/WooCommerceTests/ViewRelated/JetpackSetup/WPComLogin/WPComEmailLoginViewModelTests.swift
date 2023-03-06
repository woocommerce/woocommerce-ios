import XCTest
@testable import WooCommerce

final class WPComEmailLoginViewModelTests: XCTestCase {

    func test_title_string_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL,
                                                 requiresConnectionOnly: false,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in })

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComEmailLoginViewModel.Localization.installJetpack, text)
    }

    func test_title_string_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL,
                                                 requiresConnectionOnly: true,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in })

        // When
        let text = viewModel.titleString

        // Then
        assertEqual(WPComEmailLoginViewModel.Localization.connectJetpack, text)
    }

    func test_subtitle_string_is_correct_when_requiresConnectionOnly_is_false() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL,
                                                 requiresConnectionOnly: false,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in })

        // When
        let text = viewModel.subtitleString

        // Then
        assertEqual(WPComEmailLoginViewModel.Localization.loginToInstall, text)
    }

    func test_subtitle_string_is_correct_when_requiresConnectionOnly_is_true() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL,
                                                 requiresConnectionOnly: true,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in })

        // When
        let text = viewModel.subtitleString

        // Then
        assertEqual(WPComEmailLoginViewModel.Localization.loginToConnect, text)
    }

    func test_terms_string_is_correct() {
        // Given
        let siteURL = "https://example.com"
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL,
                                                 requiresConnectionOnly: true,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in })

        // When
        let text = viewModel.termsAttributedString.string

        // Then
        let expectedString = String(format: WPComEmailLoginViewModel.Localization.termsContent,
                                    WPComEmailLoginViewModel.Localization.termsOfService,
                                    WPComEmailLoginViewModel.Localization.shareDetails)
        assertEqual(text, expectedString)
    }

    func test_checkWordPressComAccount_triggers_requestAuthenticationLink_if_account_is_passwordless() async {
        // Given
        let mockAccountService = MockWordPressComAccountService()
        mockAccountService.shouldReturnPasswordlessAccount = true
        let viewModel = WPComEmailLoginViewModel(siteURL: "https://example.com",
                                                 requiresConnectionOnly: true,
                                                 accountService: mockAccountService,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in })
        // Confidence checks
        XCTAssertFalse(mockAccountService.triggeredIsPasswordlessAccount)
        XCTAssertFalse(mockAccountService.triggeredRequestAuthenticationLink)

        // When
        await viewModel.checkWordPressComAccount(email: "mail@example.com")

        // Then
        XCTAssertTrue(mockAccountService.triggeredIsPasswordlessAccount)
        XCTAssertTrue(mockAccountService.triggeredRequestAuthenticationLink)
    }

    func test_checkWordPressComAccount_triggers_onError_on_failure() async {
        // Given
        let mockAccountService = MockWordPressComAccountService()
        mockAccountService.passwordlessAccountCheckError = NSError(domain: "Test", code: 401)
        var triggeredOnError = false
        let viewModel = WPComEmailLoginViewModel(siteURL: "https://example.com",
                                                 requiresConnectionOnly: true,
                                                 accountService: mockAccountService,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in triggeredOnError = true })
        // When
        await viewModel.checkWordPressComAccount(email: "mail@example.com")

        // Then
        XCTAssertTrue(triggeredOnError)
    }

    func test_checkWordPressComAccount_triggers_passwordUIRequest_if_account_has_password() async {
        // Given
        let mockAccountService = MockWordPressComAccountService()
        mockAccountService.shouldReturnPasswordlessAccount = false
        var triggeredPasswordUIRequest = false
        let viewModel = WPComEmailLoginViewModel(siteURL: "https://example.com",
                                                 requiresConnectionOnly: true,
                                                 accountService: mockAccountService,
                                                 onPasswordUIRequest: { _ in triggeredPasswordUIRequest = true },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in })
        // When
        await viewModel.checkWordPressComAccount(email: "mail@example.com")

        // Then
        XCTAssertTrue(triggeredPasswordUIRequest)
    }

    func test_requestAuthenticationLink_triggers_onMagicLinkUIRequest_if_request_succeeds() async {
        // Given
        let mockAccountService = MockWordPressComAccountService()
        var triggeredOnMagicLinkUIRequest = false
        let viewModel = WPComEmailLoginViewModel(siteURL: "https://example.com",
                                                 requiresConnectionOnly: true,
                                                 accountService: mockAccountService,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in triggeredOnMagicLinkUIRequest = true },
                                                 onError: { _ in })
        // When
        await viewModel.requestAuthenticationLink(email: "mail@example.com")

        // Then
        XCTAssertTrue(triggeredOnMagicLinkUIRequest)
    }

    func test_requestAuthenticationLink_triggers_onError_if_request_fails() async {
        // Given
        let mockAccountService = MockWordPressComAccountService()
        mockAccountService.authenticationLinkRequestError = NSError(domain: "Test", code: 401)
        var triggeredOnError = false
        let viewModel = WPComEmailLoginViewModel(siteURL: "https://example.com",
                                                 requiresConnectionOnly: true,
                                                 accountService: mockAccountService,
                                                 onPasswordUIRequest: { _ in },
                                                 onMagicLinkUIRequest: { _ in },
                                                 onError: { _ in triggeredOnError = true })
        // When
        await viewModel.requestAuthenticationLink(email: "mail@example.com")

        // Then
        XCTAssertTrue(triggeredOnError)
    }
}
