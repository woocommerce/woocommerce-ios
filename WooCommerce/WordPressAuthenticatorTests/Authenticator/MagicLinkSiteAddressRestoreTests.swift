import Testing
import UIKit
@testable import WordPressAuthenticator

/// Tests that magic-link consumption restores the saved site address only when the caller opts in
/// (email magic link), not for QR login which shares the same `.login` code path.
///
/// `openAuthenticationURL` reads the process-wide `MagicLinkSiteAddressStorage.shared`, so these can't
/// use an ephemeral store. Serialize and clear around each test so state can't race or leak to disk.
@MainActor
@Suite(.serialized)
final class MagicLinkSiteAddressRestoreTests {

    init() { _ = MagicLinkSiteAddressStorage.shared.consume() }
    deinit { _ = MagicLinkSiteAddressStorage.shared.consume() }

    @Test func test_openAuthenticationURL_when_restoresSiteAddress_is_false_then_saved_address_is_not_consumed() {
        // Given a saved store address and a QR-login-style callback (no `flow`)
        WordPressAuthenticator.initializeForTesting()
        MagicLinkSiteAddressStorage.shared.save("https://qr-should-not-touch.com")
        let url = URL(string: "woocommerce://magic-login?token=token")!

        // When the URL is handled without restoring the site address (QR login opts out)
        _ = WordPressAuthenticator.openAuthenticationURL(url,
                                                         fromRootViewController: UIViewController(),
                                                         restoresSiteAddress: false,
                                                         automatedTesting: true)

        // Then the saved address is left untouched so QR login can't inherit a stale one
        #expect(MagicLinkSiteAddressStorage.shared.consume() == "https://qr-should-not-touch.com")
    }

    @Test func test_openAuthenticationURL_when_restoresSiteAddress_is_true_then_saved_address_is_consumed() {
        // Given a saved store address and an email magic-link callback
        WordPressAuthenticator.initializeForTesting()
        MagicLinkSiteAddressStorage.shared.save("https://magic-link.com")
        let url = URL(string: "woocommerce://magic-login?token=token&flow=login")!

        // When the URL is handled with restore enabled (email magic link opts in)
        _ = WordPressAuthenticator.openAuthenticationURL(url,
                                                         fromRootViewController: UIViewController(),
                                                         restoresSiteAddress: true,
                                                         automatedTesting: true)

        // Then the saved address was consumed (read-once) during the restore
        #expect(MagicLinkSiteAddressStorage.shared.consume() == nil)
    }
}
