import Foundation
@testable import WooCommerce

struct MockWPAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProviderProtocol {
    let wpAdminTaxSettingsURL: URL?

    func provideWpAdminTaxSettingsURL() -> URL? {
        wpAdminTaxSettingsURL
    }
}
