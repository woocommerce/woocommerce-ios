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
        // TODO
    }

    func decidePolicy(for navigationURL: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("🧭 \(navigationURL.absoluteString)")
        switch navigationURL.absoluteString {
        case let url where url.hasPrefix(Constants.completionURL):
            decisionHandler(.cancel)
            // TODO: analytics
            completionHandler()
        default:
            decisionHandler(.allow)
        }
    }
}

private extension WooSetupWebViewModel {
    enum Localization {
        static let title = NSLocalizedString("WooCommerce Setup", comment: "Title for the WooCommerce Setup screen in the login flow")
    }

    enum Constants {
        static let installWooCommerceURL = "https://wordpress.com/plugins/woocommerce/"
        static let completionURL = "https://public-api.wordpress.com/wpcom/v2/marketplace/products/woocommerce"
    }
}
