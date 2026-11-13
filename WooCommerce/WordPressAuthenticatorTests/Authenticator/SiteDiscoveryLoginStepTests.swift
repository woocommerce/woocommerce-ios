import Testing
import UIKit
@testable import WordPressAuthenticator

/// Site discovery opens from the in-app store switcher as well as from login, so the caller
/// decides whether the address screen reports a login step.
@MainActor
struct SiteDiscoveryLoginStepTests {

    @Test func test_siteDiscoveryUI_when_opened_from_login_then_the_screen_tracks_login_steps() {
        // Given
        WordPressAuthenticator.initializeForTesting()

        // When
        let controller = WordPressAuthenticator.siteDiscoveryUI(tracksLoginSteps: true)

        // Then
        #expect((controller as? SiteAddressViewController)?.tracksLoginSteps == true)
    }

    @Test func test_siteDiscoveryUI_when_opened_outside_login_then_the_screen_tracks_no_login_steps() {
        // Given
        WordPressAuthenticator.initializeForTesting()

        // When the store switcher opens site discovery, which is not a login journey
        let controller = WordPressAuthenticator.siteDiscoveryUI(tracksLoginSteps: false)

        // Then
        #expect((controller as? SiteAddressViewController)?.tracksLoginSteps == false)
    }
}
