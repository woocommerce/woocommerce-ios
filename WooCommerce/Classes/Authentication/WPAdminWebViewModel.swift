import Foundation
import WebKit

/// A view model for authenticated web view for a wp-admin URL in self-hosted sites when WPCOM login is enabled as a Jetpack feature at
/// `/wp-admin/admin.php?page=jetpack#/settings`.
class WPAdminWebViewModel: AuthenticatedWebViewModel, WebviewReloadable {
    /// Set in `AuthenticatedWebViewController`.
    var reloadWebview: () -> Void = {}

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
        guard let url else {
            return
        }

        if shouldReload(for: url) {
            reloadWebview()
        }
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }
}
