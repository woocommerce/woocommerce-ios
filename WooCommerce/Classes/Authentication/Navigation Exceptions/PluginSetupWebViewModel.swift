import Foundation
import WebKit

/// Abstracts different configurations and logic for web view controllers
/// used for setting up plugins during the login flow
protocol PluginSetupWebViewModel {
    /// Title for the view
    var title: String { get }

    /// Initial URL to be loaded on the web view
    var initialURL: URL? { get }

    /// Triggered when the web view is dismissed
    func handleDismissal()

    /// Handler for a navigation URL
    func decidePolicy(for navigationURL: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
}
