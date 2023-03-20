import Foundation
import WebKit

protocol WebviewReloadable {
    /// Allows the view model to load a URL in the webview at anytime.
    /// This is useful when we have custom redirect handling for WordPress.com login in self-hosted states.
    var loadWebview: (_ url: URL) -> Void { get set }
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

    /// Handler for a navigation URL
    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy
}
