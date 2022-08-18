import Foundation
import WebKit

final class WooSetupWebViewModel: PluginSetupWebViewModel {
    private let siteURL: String
    private let analytics: Analytics
    private let completionHandler: () -> Void
    private let dismissHandler: () -> Void
    private var hasCompleted = false

    init(siteURL: String, analytics: Analytics = ServiceLocator.analytics, onCompletion: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.siteURL = siteURL
        self.analytics = analytics
        self.completionHandler = onCompletion
        self.dismissHandler = onDismiss
    }

    // MARK: - `PluginSetupWebViewModel` conformance
    var title: String { Localization.title }

    var initialURL: URL? {
        URL(string: Constants.installWooCommerceURL + siteURL.trimHTTPScheme())
    }

    func handleDismissal() {
        if !hasCompleted {
            analytics.track(event: .LoginWooCommerceSetup.setupDismissed(source: .web))
        }
    }

    func handleRedirect(for url: URL?) {
        guard let path = url?.absoluteString else {
            return
        }
        switch path {
        case path where path.hasPrefix(Constants.completionURL):
            analytics.track(event: .LoginWooCommerceSetup.setupCompleted(source: .web))
            hasCompleted = true
            completionHandler()
        case path where path == Constants.pluginsURL + siteURL.trimHTTPScheme():
            // When user taps the Back button on the web view, the plugins page is displayed.
            // Dismiss the web view in this case.
            handleDismissal()
            dismissHandler()
        default:
            break
        }
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        return .allow
    }
}

private extension WooSetupWebViewModel {
    enum Localization {
        static let title = NSLocalizedString("WooCommerce Setup", comment: "Title for the WooCommerce Setup screen in the login flow")
    }

    enum Constants {
        static let installWooCommerceURL = "https://wordpress.com/plugins/woocommerce/"
        static let completionURL = "https://wordpress.com/marketplace/thank-you/woocommerce/"
        static let pluginsURL = "https://wordpress.com/plugins/"
    }
}
