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
}

extension AuthenticatedWebViewModel {
    /// Default implementation for the optional method
    func decidePolicy(for response: URLResponse) async -> WKNavigationResponsePolicy {
        return .allow
    }
}
