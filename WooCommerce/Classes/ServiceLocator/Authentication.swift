import Foundation
import UIKit
import WordPressAuthenticator

/// Abstracts the Authentication engine.
///
protocol Authentication {

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
    func initialize()
}
