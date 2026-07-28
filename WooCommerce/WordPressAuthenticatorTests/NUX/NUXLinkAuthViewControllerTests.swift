import Testing
import UIKit
@testable import WordPressAuthenticator

/// Tests `NUXLinkAuthViewController` credential building after magic-link consumption.
@MainActor
struct NUXLinkAuthViewControllerTests {

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
