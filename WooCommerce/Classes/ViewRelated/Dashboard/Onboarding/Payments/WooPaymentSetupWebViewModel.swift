import Foundation
import WebKit

/// A view model for authenticated web view for setting up WCPay
final class WooPaymentSetupWebViewModel: AuthenticatedWebViewModel, WebviewReloadable {
    /// Set in `AuthenticatedWebViewController`.
    var reloadWebview: () -> Void = {}

    let title: String
    let initialURL: URL?
    let completionHandler: (_ isSuccess: Bool) -> Void

    init(title: String = "",
         initialURL: URL,
         onCompletion: @escaping (Bool) -> Void) {
        self.title = title
        self.initialURL = initialURL
        self.completionHandler = onCompletion
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

        let urlString = url.absoluteString
        if urlString.contains(Constants.successParam) {
            completionHandler(true)
        } else if urlString.contains(Constants.errorParam) {
            completionHandler(false)
        }
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }
}

private extension WooPaymentSetupWebViewModel {
    enum Constants {
        static let successParam = "wcpay-connection-success"
        static let errorParam = "wcpay-connection-error"
    }
}
