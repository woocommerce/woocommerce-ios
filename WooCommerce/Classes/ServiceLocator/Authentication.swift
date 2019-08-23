import Foundation
import UIKit
import WordPressAuthenticator

/// Abstracts the Authentication engine.
///
protocol Authentication {

    /// Returns a LoginViewController preinitialized for WordPress.com
    ///
    func loginForWordPressDotCom() -> UIViewController

    /// Presents the Support Interface from a given ViewController, with a specified SourceTag.
    ///
    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag)

    /// Handles an Authentication URL Callback. Returns *true* on success.
    ///
    func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool

    /// Displays the Login Flow using the specified UIViewController as presenter.
    ///
    func displayAuthentication(from presenter: UIViewController)

    /// Initializes the WordPress Authenticator.
    ///
    func initialize()
}
