import Foundation
import WebKit

final class WPComPreviewWebViewModel {
    let title = "Preview"
    let initialURL: URL?

    init(previewURL: URL?) {
        self.initialURL = previewURL
    }
}

extension WPComPreviewWebViewModel: AuthenticatedWebViewModel {
    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }

    func handleDismissal() {
        // no-op
    }

    func handleRedirect(for url: URL?) {
        DDLogInfo("Redirected to \(url?.absoluteString ?? "")")
    }


}
