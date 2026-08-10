import Testing
import UIKit
@testable import WordPressAuthenticator

/// Tests `NUXLinkAuthViewController` credential building after magic-link consumption.
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

    @Test func test_makeCredentials_when_site_address_entered_then_siteURL_matches_entered_address() {
        // Given a controller with the store address entered at the start of the login flow
        WordPressAuthenticator.initializeForTesting()
        let controller = NUXLinkAuthViewController()
        controller.loginFields.siteAddress = "https://yourwoosite.com"

        // When building the credentials used to sync the account after magic-link consumption
        let credentials = controller.makeCredentials(authToken: "token", isJetpackConnect: false)

        // Then the credential carries the entered address so the epilogue can match and route to that store
        #expect(credentials.wpcom?.siteURL == "https://yourwoosite.com")
    }

    @Test func test_makeCredentials_when_no_site_address_then_siteURL_falls_back_to_wordpress_com() {
        // Given a controller with no entered store address (generic entry)
        WordPressAuthenticator.initializeForTesting()
        let controller = NUXLinkAuthViewController()
        controller.loginFields.siteAddress = ""

        // When building the credentials
        let credentials = controller.makeCredentials(authToken: "token", isJetpackConnect: false)

        // Then it falls back to wordpress.com, preserving the pre-fix store-picker behavior for this case
        #expect(credentials.wpcom?.siteURL == "https://wordpress.com")
    }
}
