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

/// Encapsulates the logic related to the provision of the Site URLs that point to plugins related content
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
}
