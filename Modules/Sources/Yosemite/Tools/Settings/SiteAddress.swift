import Foundation
import WooFoundation

/// Represent and parse the Address of the store, returned in the SiteSettings API `/settings/general/`
///
public class SiteAddress {

    private let siteSettings: [SiteSetting]

    public var address: String {
        return getValueFromSiteSettings(Constants.address) ?? ""
    }

    public var address2: String {
        return getValueFromSiteSettings(Constants.address2) ?? ""
    }

    public var city: String {
        return getValueFromSiteSettings(Constants.city) ?? ""
    }

    public var postalCode: String {
        return getValueFromSiteSettings(Constants.postalCode) ?? ""
    }

    public var countryCode: CountryCode {
        guard let countryComponent = getCountryAndStateComponents().first else {
            DDLogError("⛔️ Could not determine country code for site address: no country component found.")
            return .unknown
        }
        guard let countryCode = CountryCode(rawValue: countryComponent) else {
            DDLogError("⛔️ Could not determine country code for country: \(countryComponent)")
            return .unknown
        }
        return countryCode
    }

    /// Returns the name of the country associated with the current store.
    /// The default store country is provided in a format like `HK:KOWLOON`
    /// This method will transform `HK:KOWLOON` into `Hong Kong`
    /// Will return nil if it can not figure out a valid country name
    public var countryName: String? {
        guard countryCode != .unknown else {
            return nil
        }

        return countryCode.readableCountry
    }

    public var state: String {
        return getCountryAndStateComponents().last ?? ""
    }

    public init(siteSettings: [SiteSetting]) {
        self.siteSettings = siteSettings
    }

    private func getCountryAndStateComponents() -> [String] {
        getValueFromSiteSettings(Constants.countryAndState)?.components(separatedBy: ":") ?? []
    }

    private func getValueFromSiteSettings(_ settingID: String) -> String? {
        return siteSettings.first { (setting) -> Bool in
            return setting.settingID == settingID
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
