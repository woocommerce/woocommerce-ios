import Yosemite
import WooFoundation

struct TaxEducationalDialogViewModel {
    struct TaxLine {
        let title: String
        let value: String
    }

    let taxLines: [TaxLine]
    let taxBasedOnSettingExplanatoryText: String?
    private let stores: StoresManager
    private let analytics: Analytics

    init(orderTaxLines: [OrderTaxLine], taxBasedOnSetting: TaxBasedOnSetting?, stores: StoresManager = ServiceLocator.stores, analytics: Analytics = ServiceLocator.analytics) {
        self.taxLines = orderTaxLines.map { TaxLine(title: $0.label, value: $0.ratePercent.percentFormatted() ?? "") }
        self.taxBasedOnSettingExplanatoryText = taxBasedOnSetting?.explanatoryText
        self.stores = stores
        self.analytics = analytics
    }

    /// WPAdmin URL to navigate user to edit the tax settings
    var wpAdminTaxSettingsURL: URL? {
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

    func onGoToWpAdminButtonTapped() {
        analytics.track(event: WooAnalyticsEvent.Orders.taxEducationalDialogEditInAdminButtonTapped())
    }
}

private extension TaxEducationalDialogViewModel {
    enum Constants {
        static let wpAdminPath: String = "/wp-admin/"
        static let wpAdminTaxSettingsPath: String = "admin.php?page=wc-settings&tab=tax"
    }
}

private extension TaxBasedOnSetting {
    var explanatoryText: String {
        switch self {
        case .customerBillingAddress:
            return NSLocalizedString("Your tax rate is currently calculated based on the customer billing address:",
                                     comment: "Educational tax dialog to explain that the rate is calculated based on the customer billing address.")
        case .customerShippingAddress:
            return NSLocalizedString("Your tax rate is currently calculated based on the customer shipping address:",
                                     comment: "Educational tax dialog to explain that the rate is calculated based on the customer shipping address.")
        case .shopBaseAddress:
            return NSLocalizedString("Your tax rate is currently calculated based on your shop address:",
                                     comment: "Educational tax dialog to explain that the rate is calculated based on the shop address.")
        }
    }
}
