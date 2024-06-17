import Foundation
import UIKit
import WordPressAuthenticator

/// Abstracts the Authentication engine.
///
@MainActor
protocol Authentication {

    /// Displays the authentication UI if the app is logged out, and returns the login navigation controller.
    @MainActor var displayAuthenticatorIfLoggedOut: (() -> UINavigationController?)? { get set }

    /// Presents the Support Interface
    ///
    /// - Parameters:
    ///     - from: UIViewController instance from which to present the support interface
    ///     - screen: A case from `CustomHelpCenterContent.Screen` enum. This represents authentication related screens from WCiOS.
    ///
    @MainActor func presentSupport(from sourceViewController: UIViewController, screen: CustomHelpCenterContent.Screen)

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    @MainActor func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag)

    /// Handles an Authentication URL Callback. Returns *true* on success.
    ///
    @MainActor func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool

    /// Returns authentication UI for display by the caller.
    ///
    @MainActor func authenticationUI() -> UIViewController

    /// Initializes the WordPress Authenticator.
    ///
    @MainActor func initialize()

    /// Injects `loggedOutAppSettings`
    ///
    func setLoggedOutAppSettings(_ settings: LoggedOutAppSettingsProtocol)

    /// Checks the given site address and see if it's valid
    /// and returns an error view controller if not.
    ///
    func errorViewController(for siteURL: String,
                             with matcher: ULAccountMatcher,
                             credentials: AuthenticatorCredentials?,
                             navigationController: UINavigationController,
                             onStorePickerDismiss: @escaping () -> Void) -> UIViewController?
}
