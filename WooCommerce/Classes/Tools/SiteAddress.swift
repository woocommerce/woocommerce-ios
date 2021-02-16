import Foundation
import Yosemite


/// Represent and parse the Address of the store, returned in the SiteSettings API `/settings/general/`
///
final class SiteAddress {

    private let siteSettings: [SiteSetting]

    var address: String {
        return getValueFromSiteSettings(Constants.address) ?? ""
    }
    
    var address2: String {
        return getValueFromSiteSettings(Constants.address2) ?? ""
    }
    
    var city: String {
        return getValueFromSiteSettings(Constants.city) ?? ""
    }
    
    var postalCode: String {
        return getValueFromSiteSettings(Constants.postalCode) ?? ""
    }
    
    var country: String {
        return getValueFromSiteSettings(Constants.countryAndState)?.components(separatedBy: ":").first ?? ""
    }
    
    var state: String {
        return getValueFromSiteSettings(Constants.countryAndState)?.components(separatedBy: ":").last ?? ""
    }

    init(siteSettings: [SiteSetting] = ServiceLocator.selectedSiteSettings.siteSettings) {
        self.siteSettings = siteSettings
    }
    
    private func getValueFromSiteSettings(_ settingID: String) -> String?{
        return siteSettings.first { (setting) -> Bool in
                    return setting.settingID.contains(settingID)
                }?.value
    }
}

// MARK: - Constants.
//
private extension SiteAddress {
    /// The key of the SiteSetting containing the store address
    enum Constants {
        static let address = "woocommerce_store_address"
        static let address2 = "woocommerce_store_address_2"
        static let city = "woocommerce_store_city"
        static let postalCode = "woocommerce_store_postcode"
        static let countryAndState = "woocommerce_default_country"
    }
}
