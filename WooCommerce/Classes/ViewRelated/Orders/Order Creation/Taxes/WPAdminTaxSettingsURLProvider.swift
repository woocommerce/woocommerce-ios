import Foundation
import Yosemite

protocol WPAdminTaxSettingsURLProviderProtocol {
    func provideWpAdminTaxSettingsURL() -> URL?
}

/// Provides the url to navigate to the Tax settings section in wp-admin
///
struct WPAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProviderProtocol {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    /// WPAdmin URL to navigate user to edit the tax settings
    func provideWpAdminTaxSettingsURL() -> URL? {
        guard let site = stores.sessionManager.defaultSite else {
            return nil
        }

        var path = site.adminURL

        if !path.hasValidSchemeForBrowser {
            // fall back to constructing the path from siteURL and WP admin path
            if site.url.hasValidSchemeForBrowser {
                path = site.url + Constants.wpAdminPath
            } else {
                return nil
            }
        }

        return URL(string: "\(path)\(Constants.wpAdminTaxSettingsPath)")
    }
}

private extension WPAdminTaxSettingsURLProvider {
    enum Constants {
        static let wpAdminPath: String = "/wp-admin/"
        static let wpAdminTaxSettingsPath: String = "admin.php?page=wc-settings&tab=tax"
    }
}
