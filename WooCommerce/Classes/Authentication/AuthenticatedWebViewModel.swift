import Foundation
import WebKit

/// Optional conformance for a `AuthenticatedWebViewModel` implementation to reload a webview asynchronously.
protocol WebviewReloadable {
    /// Allows the view model to reload the initial URL in the webview at anytime.
    /// This is useful when we have custom redirect handling for WordPress.com login in self-hosted sites where WPCOM authentication
    /// does not redirect to the initial URL.
    var reloadWebview: () -> Void { get set }
}

/// Abstracts different configurations and logic for web view controllers
/// which are authenticated for WordPress.com, where possible
protocol AuthenticatedWebViewModel {
    /// Title for the view
    var title: String { get }

    /// Initial URL to be loaded on the web view
    var initialURL: URL? { get }

    /// Triggered when the web view is dismissed
    func handleDismissal()

    /// Triggered when the web view redirects to a new URL
    func handleRedirect(for url: URL?)

    /// Handler for a navigation URL before the navigation
    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy

    /// Handler after receiving response for a navigation
    func decidePolicy(for response: URLResponse) async -> WKNavigationResponsePolicy

    /// Triggered when a navigation completes.
    func didFinishNavigation(for url: URL)

    /// Triggered when provisional navigation fails
    ///
    func didFailProvisionalNavigation(with error: Error)
}

// MARK: Default implementation for the optional methods
//
extension AuthenticatedWebViewModel {
    func decidePolicy(for response: URLResponse) async -> WKNavigationResponsePolicy {
        return .allow
    }

    func didFinishNavigation(for url: URL) {
        // NO-OP
    }

    func didFailProvisionalNavigation(with error: Error) {
        // NO-OP
    }
}

// MARK: - Helper methods
extension AuthenticatedWebViewModel {
    /// If the site allows login with WPCOM as a Jetpack feature,
    /// WPCOM authentication is complete after redirecting to the WPCOM homepage.
    /// This checks for the redirect URL to decide if the initial page should be reloaded.
    ///
    func shouldReload(for url: URL) -> Bool {

        let urlAfterWPComAuth = "https://wordpress.com"

        if  url.absoluteString.removingSuffix("/") == urlAfterWPComAuth,
           initialURL?.absoluteString != urlAfterWPComAuth {
            return true
        }
        return false
    }
}
