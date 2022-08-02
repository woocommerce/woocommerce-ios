import Foundation
import WebKit

struct WooSetupWebViewModel: PluginSetupWebViewModel {
    private let siteURL: String
    private let analytics: Analytics

    init(siteURL: String, analytics: Analytics = ServiceLocator.analytics) {
        self.siteURL = siteURL
        self.analytics = analytics
    }

    // MARK: - `PluginSetupWebViewModel` conformance
    var title: String { Localization.title }

    var initialURL: URL? {
        URL(string: Constants.installWooCommerceURLString + siteURL.trimHTTPScheme())
    }

    func trackDismissal() {
        // TODO
    }

    func decidePolicy(for navigationURL: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("🧭 \(navigationURL.absoluteString)")
        decisionHandler(.allow)
    }
}

private extension WooSetupWebViewModel {
    enum Localization {
        static let title = NSLocalizedString("WooCommerce Setup", comment: "Title for the WooCommerce Setup screen in the login flow")
    }

    enum Constants {
        static let installWooCommerceURLString = "https://wordpress.com/plugins/woocommerce/"
    }
}
