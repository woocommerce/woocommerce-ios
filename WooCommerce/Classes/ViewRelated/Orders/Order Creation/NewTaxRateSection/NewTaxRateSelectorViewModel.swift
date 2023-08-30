import Foundation

struct NewTaxRateSelectorViewModel {
    // Demo values. To be removed once we fetch the tax rates remotely
    struct DemoTaxRate {
        let title: String
        let value: String
    }

    let demoTaxRates: [DemoTaxRate] = [DemoTaxRate(title: "Government Sales Tax · US CA 94016 San Francisco", value: "10%"),
                                       DemoTaxRate(title: "GST · US CA", value: "10%"),
                                       DemoTaxRate(title: "GST · AU", value: "10%")]

    private let wpAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProvider

    init(wpAdminTaxSettingsURLProvider: WPAdminTaxSettingsURLProvider = WPAdminTaxSettingsURLProvider()) {
        self.wpAdminTaxSettingsURLProvider = wpAdminTaxSettingsURLProvider
    }

    /// WPAdmin URL to navigate user to edit the tax settings
    var wpAdminTaxSettingsURL: URL? {
        wpAdminTaxSettingsURLProvider.wpAdminTaxSettingsURL
    }
}
