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

extension Site {
    var pluginsURL: String {
        adminURL + "/plugins.php"
    }

    func pluginSettingsSectionURL(from plugin: CardPresentPaymentsPlugin) -> String {
        adminURL + "admin.php?page=wc-settings&tab=checkout&section=" + plugin.setupURLSectionPath
    }
}
