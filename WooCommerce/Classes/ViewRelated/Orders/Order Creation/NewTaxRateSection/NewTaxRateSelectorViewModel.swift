import Foundation

struct NewTaxRateSelectorViewModel {
    private let wpAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProvider

    init(wpAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProvider = WPAdminTaxSettingsURLProvider()) {
        self.wpAdminTaxSettingsURLProvider = wpAdminTaxSettingsURLProvider
    }

    /// WPAdmin URL to navigate user to edit the tax settings
    var wpAdminTaxSettingsURL: URL? {
        wpAdminTaxSettingsURLProvider.wpAdminTaxSettingsURL
    }
}
