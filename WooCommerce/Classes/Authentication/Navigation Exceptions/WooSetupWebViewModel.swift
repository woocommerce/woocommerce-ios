import Foundation
import WebKit

struct WooSetupWebViewModel: PluginSetupWebViewModel {
    private let siteURL: String
    private let analytics: Analytics
    private let completionHandler: () -> Void

    init(siteURL: String, analytics: Analytics = ServiceLocator.analytics, onCompletion: @escaping () -> Void) {
        self.siteURL = siteURL
        self.analytics = analytics
        self.completionHandler = onCompletion
    }

    // MARK: - `PluginSetupWebViewModel` conformance
    var title: String { Localization.title }

    var initialURL: URL? {
        URL(string: Constants.installWooCommerceURL + siteURL.trimHTTPScheme())
    }

    func handleDismissal() {
        analytics.track(event: .LoginWooCommerceSetup.setupDismissed(source: .web))
    }

    func handleRedirect(for url: URL?) {
        if let url = url, url.absoluteString.hasPrefix(Constants.completionURL) {
            analytics.track(event: .LoginWooCommerceSetup.setupCompleted(source: .web))
            completionHandler()
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
    }
}
