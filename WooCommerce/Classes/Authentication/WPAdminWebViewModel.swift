import Foundation
import WebKit

/// A view model for authenticated web view for a wp-admin URL in self-hosted sites when WPCOM login is enabled as a Jetpack feature at
/// `/wp-admin/admin.php?page=jetpack#/settings`.
final class WPAdminWebViewModel: AuthenticatedWebViewModel, WebviewReloadable {
    /// Set in `AuthenticatedWebViewController`.
    var loadWebview: (URL) -> Void = { _ in }

    let title: String
    let initialURL: URL?

    init(title: String = "",
         initialURL: URL) {
        self.title = title
        self.initialURL = initialURL
    }

    func handleDismissal() {
        // no-op
    }

    func handleRedirect(for url: URL?) {
        // If the self-hosted site allows login with WPCOM as a Jetpack feature,
        // WPCOM authentication is complete after redirecting to the WPCOM homepage.
        if url?.absoluteString.removingSuffix("/") == URLs.urlAfterWPComAuth,
           initialURL?.absoluteString != URLs.urlAfterWPComAuth,
           let initialURL {
            loadWebview(initialURL)
        }
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }
}

private extension WPAdminWebViewModel {
    enum URLs {
        static let urlAfterWPComAuth = "https://wordpress.com"
    }
}
