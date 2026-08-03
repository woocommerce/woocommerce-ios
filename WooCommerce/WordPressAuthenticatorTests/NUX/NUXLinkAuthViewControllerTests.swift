import Testing
import UIKit
@testable import WordPressAuthenticator

@MainActor
struct NUXLinkAuthViewControllerTests {

    @Test func test_showLoginEpilogue_when_navigationController_is_nil_then_skips_epilogue_and_reports_without_crashing() {
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
        // And it reports the handled failure, tagged with the concrete flow, so the race stays visible after shipping
        #expect(spy.trackedEvents.contains(.loginMagicLinkFailed))
        #expect(spy.lastTrackedProperties?["reason"] as? String == "missing_navigation_controller")
        #expect(spy.lastTrackedProperties?["flow"] as? String == "NUXLinkAuthViewController")
    }
}
