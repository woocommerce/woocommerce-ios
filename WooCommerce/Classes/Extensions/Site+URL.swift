import CocoaLumberjackSwift
import Foundation
import Yosemite

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

    /// URL to update a plugin
    func pluginUpdateURL(for plugin: SystemPlugin) -> String? {
        if let directoryName = plugin.plugin.components(separatedBy: "/").first {
            return adminURL + "plugin-install.php?tab=plugin-information&plugin=" + directoryName
        }
        return nil
    }

    /// Returns the plugin URL from wp-admin that handles pending tasks or requirements during onboarding.
    ///
    func cardPresentPluginHasPendingTasksURL(plugin: CardPresentPaymentsPlugin) -> String {
        switch plugin {
        case .wcPay:
            /// Payments Connect page was recommended by the web team over Payments Overview page in pdfdoF-5Bo-p2#comment-6655
            return adminURL + "admin.php?page=wc-admin&path=%2Fpayments%2Fconnect"
        case .stripe:
            return pluginSettingsSectionURL(from: .stripe) + "&panel=settings"
        }
    }

    /// Constructs the admin URL for editing POS receipt settings.
    /// CIAB sites use the next-admin page; non-CIAB sites use the classic wc-settings page.
    /// Returns an empty string if site is nil.
    static func receiptSettingsAdminURL(site: Site?, isCIAB: Bool) -> String {
        guard let site else {
            DDLogError("⛔️ receiptSettingsAdminURL called without a site")
            return ""
        }
        if isCIAB {
            return site.adminURL + "admin.php?page=next-admin&p=%2Fwoocommerce%2Fsettings%2Fpayments%2Fpos"
        } else {
            return site.adminURL + "admin.php?page=wc-settings&tab=point-of-sale"
        }
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
