import Foundation
import Testing
@testable import WooCommerce
@testable import WordPressAuthenticator

@MainActor
struct WPComLoginCoordinatorTests {
    @Test(arguments: [
        "https://wordpress.com/wp-login.php?action=magic-login&scheme=woocommerce&token=email-code",
        "https://wordpress.com/wp-login.php?action=magic-login&scheme=woocommerce&flow=login&token=email-code"
    ])
    func test_recovery_accepts_wordpress_com_sign_in_links(link: String) throws {
        let url = try #require(URL(string: link))
        #expect(POSPINRecoveryMagicLink.isSignInLink(url, callbackScheme: "woocommerce"))
    }

    @Test(arguments: [
        "woocommerce://magic-login?token=existing-token",
        "https://wordpress.com.example.com/wp-login.php?action=magic-login&scheme=woocommerce&token=email-code",
        "https://wordpress.com/wp-login.php?action=magic-login&scheme=wordpress&token=email-code",
        "https://wordpress.com/wp-login.php?action=magic-login&scheme=woocommerce&token=first&token=second"
    ])
    func test_recovery_rejects_other_pasted_urls(link: String) throws {
        let url = try #require(URL(string: link))
        #expect(!POSPINRecoveryMagicLink.isSignInLink(url, callbackScheme: "woocommerce"))
    }

    @Test
    func test_recovery_extracts_oauth_token_from_login_callback() throws {
        let url = try #require(URL(string: "woocommerce://magic-login?flow=login&token=new-token"))
        #expect(POSPINRecoveryMagicLink.token(from: url, callbackScheme: "woocommerce") == "new-token")
    }

    @Test(arguments: [
        "woocommerce://magic-login?flow=signup&token=new-token",
        "woocommerce://magic-login.example.com?token=new-token",
        "woocommerce://magic-login?token=first&token=second"
    ])
    func test_recovery_rejects_other_browser_callbacks(link: String) throws {
        let url = try #require(URL(string: link))
        #expect(POSPINRecoveryMagicLink.token(from: url, callbackScheme: "woocommerce") == nil)
    }

    @Test
    func test_password_login_failure_when_credentials_are_incorrect_then_shows_the_server_error_message() async throws {
        // Given
        let navigationController = UINavigationController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let accountService = MockWordPressComAccountService()
        accountService.shouldReturnPasswordlessAccount = false
        let coordinator = WPComLoginCoordinator(
            flow: .jetpackSetup(requiresConnectionOnly: false),
            navigationController: navigationController,
            stores: MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false)),
            accountService: accountService,
            completionHandler: { _ in }
        )
        let expectedMessage = "Incorrect username or password."
        let error = WordPressComOAuthError.endpointError(AuthenticationFailure(apiJSONResponse: [
            "error": "invalid_request" as AnyObject,
            "error_description": expectedMessage as AnyObject
        ]))
        await coordinator.start(with: "email@test.com")
        let passwordController = try #require(navigationController.topViewController as? WPComPasswordLoginHostingController)

        // When
        passwordController.viewModel.displayRemoteError(error)

        // Then
        let alert = try #require(navigationController.topmostPresentedViewController as? UIAlertController)
        #expect(alert.title == expectedMessage)
    }
}
