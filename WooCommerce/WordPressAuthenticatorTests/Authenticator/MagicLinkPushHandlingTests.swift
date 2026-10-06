import Testing
import UIKit
@testable import WordPressAuthenticator

/// Tests the push-based magic-link handling used by QR login, which must keep the sign-in screen
/// on the given navigation stack so the login epilogue can run. (WOOMOB-4262)
@MainActor
struct MagicLinkPushHandlingTests {

    @Test func test_handleWordPressAuthUrl_pushingOnto_when_login_link_then_pushes_link_auth_onto_given_navigation_controller() {
        // Given
        WordPressAuthenticator.initializeForTesting()
        let spy = WordPressAuthenticatorDelegateSpy()
        WordPressAuthenticator.shared.delegate = spy
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let url = URL(string: "woocommerce://magic-login?token=token")!

        // When
        let handled = WordPressAuthenticator.shared.handleWordPressAuthUrl(url,
                                                                           pushingOnto: navigationController,
                                                                           restoresSiteAddress: false)

        // Then
        #expect(handled)
        let linkAuthViewController = navigationController.topViewController as? NUXLinkAuthViewController
        #expect(linkAuthViewController != nil)
        #expect(linkAuthViewController?.navigationController === navigationController)
        #expect(linkAuthViewController?.navigationItem.hidesBackButton == true)
    }

    @Test func test_handleWordPressAuthUrl_pushingOnto_when_sync_completes_then_presents_login_epilogue_in_given_navigation_controller() {
        // Given
        WordPressAuthenticator.initializeForTesting()
        let spy = WordPressAuthenticatorDelegateSpy()
        spy.completesSync = true
        WordPressAuthenticator.shared.delegate = spy
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let url = URL(string: "woocommerce://magic-login?token=token")!

        // When
        _ = WordPressAuthenticator.shared.handleWordPressAuthUrl(url,
                                                                 pushingOnto: navigationController,
                                                                 restoresSiteAddress: false)

        // Then
        #expect(spy.presentLoginEpilogueCalled)
        #expect(spy.loginEpilogueNavigationController === navigationController)
        #expect(spy.trackedEvents.contains(.loginMagicLinkFailed) == false)
    }

    @Test func test_handleWordPressAuthUrl_pushingOnto_when_url_has_no_token_then_returns_false_and_pushes_nothing() {
        // Given
        WordPressAuthenticator.initializeForTesting()
        let spy = WordPressAuthenticatorDelegateSpy()
        WordPressAuthenticator.shared.delegate = spy
        let rootViewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        let url = URL(string: "woocommerce://magic-login?flow=login")!

        // When
        let handled = WordPressAuthenticator.shared.handleWordPressAuthUrl(url,
                                                                           pushingOnto: navigationController,
                                                                           restoresSiteAddress: false)

        // Then
        #expect(handled == false)
        #expect(navigationController.viewControllers == [rootViewController])
    }
}
