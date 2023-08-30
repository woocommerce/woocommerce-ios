import Foundation
import WebKit

/// A view model for authenticated web view for setting up WCPay
final class WooPaymentSetupWebViewModel: AuthenticatedWebViewModel, WebviewReloadable {
    /// Set in `AuthenticatedWebViewController`.
    var reloadWebview: () -> Void = {}

    let title: String
    let initialURL: URL?
    let completionHandler: () -> Void

    init(title: String = "",
         initialURL: URL,
         onCompletion: @escaping () -> Void) {
        self.title = title
        self.initialURL = initialURL
        self.completionHandler = onCompletion
    }

    func handleDismissal() {
        // no-op
    }

    func handleRedirect(for url: URL?) {
        guard let urlString = url?.absoluteString else {
            return
        }
        // If the self-hosted site allows login with WPCOM as a Jetpack feature,
        // WPCOM authentication is complete after redirecting to the WPCOM homepage.
        if urlString.removingSuffix("/") == Constants.urlAfterWPComAuth,
           initialURL?.absoluteString != Constants.urlAfterWPComAuth {
            reloadWebview()
        }

        if urlString.contains(Constants.successParam) ||
            urlString.contains(Constants.errorParam) {
            completionHandler()
        }
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }
}

extension WooPaymentSetupWebViewModel {
    enum Constants {
        static let urlAfterWPComAuth = "https://wordpress.com"
        static let successParam = "wcpay-connection-success"
        static let errorParam = "wcpay-connection-error"
    }
}
