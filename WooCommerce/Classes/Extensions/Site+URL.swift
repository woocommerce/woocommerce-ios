import Yosemite
import Foundation

private extension CardPresentPaymentsPlugin {
    var setupURLSectionPath: String {
        switch self {
        case .wcPay:
            return "woocommerce_payments"
        case .stripe:
            return "stripe"
        }
    }
}

/// Encapsulates the logic related to the provision of the Site URLs
///
extension Site {
    /// Site's plugins section in wp-admin.
    ///
    var pluginsURL: String {
        adminURL + "plugins.php"
    }
    /// Payment plugin settings in wp-admin. This can be helpful when the plugin needs to be setup completely.
    /// 
    func pluginSettingsSectionURL(from plugin: CardPresentPaymentsPlugin) -> String {
        adminURL + "admin.php?page=wc-settings&tab=checkout&section=" + plugin.setupURLSectionPath
    }

    /// Returns the plugin URL from wp-admin that handles pending tasks or requirements during onboarding.
    /// Both WCPay and Stripe use the same URL.
    ///
    func cardPresentPluginHasPendingTasksURL() -> String {
        return adminURL + "admin.php?page=wc-admin&path=%2Fpayments%2Foverview"
    }

    /// Returns the WooCommerce admin URL, or attempts to construct it from the site URL.
    ///
    func adminURLWithFallback() -> URL? {
        guard let adminURL = URL(string: adminURL) else {
            let adminURLFromSiteURLString = url + "/wp-admin"
            return URL(string: adminURLFromSiteURLString)
        }
        return adminURL
    }
}
