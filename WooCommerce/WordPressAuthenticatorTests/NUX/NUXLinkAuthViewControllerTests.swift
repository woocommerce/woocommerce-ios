import Testing
import UIKit
@testable import WordPressAuthenticator

@MainActor
struct NUXLinkAuthViewControllerTests {

    @Test func test_showLoginEpilogue_when_navigationController_is_nil_then_does_not_crash_and_skips_epilogue() {
        // Given a controller orphaned from its navigation stack (nav controller nil)
        WordPressAuthenticator.initializeForTesting()
        let spy = WordPressAuthenticatorDelegateSpy()
        WordPressAuthenticator.shared.delegate = spy
        let controller = NUXLinkAuthViewController()
        let credentials = AuthenticatorCredentials(wpcom: WordPressComCredentials(authToken: "token",
                                                                                  isJetpackLogin: false,
                                                                                  multifactor: false,
                                                                                  siteURL: "https://wordpress.com"))

        // When showing the login epilogue on the orphaned controller
        controller.showLoginEpilogue(for: credentials)

        // Then it skips the epilogue instead of trapping — an orphaned epilogue is recoverable, not fatal
        #expect(spy.presentLoginEpilogueCalled == false)
    }
}
