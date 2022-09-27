import Foundation
import UIKit
import WordPressAuthenticator

/// Abstracts the Authentication engine.
///
protocol Authentication {

    /// Presents the Support Interface
    ///
    /// - Parameters:
    ///     - from: UIViewController instance from which to present the support interface
    ///     - screen: A case from `CustomHelpCenterContent.Screen` enum. This represents authentication related screens from WCiOS.
    ///
    func presentSupport(from sourceViewController: UIViewController, screen: CustomHelpCenterContent.Screen)

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag)

    /// Handles an Authentication URL Callback. Returns *true* on success.
    ///
    func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool

    /// Returns authentication UI for display by the caller.
    ///
    func authenticationUI() -> UIViewController

    /// Initializes the WordPress Authenticator.
    ///
    func initialize(loggedOutAppSettings: LoggedOutAppSettingsProtocol)

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
