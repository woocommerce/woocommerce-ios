import Foundation
import Yosemite

/// Validation logic for Shipping scenarios with specific EU Customs.
///
/// Refer to [USPS instructions](https://www.usps.com/international/new-eu-customs-rules.htm) for more context.
///
struct EUCustomsScenarioValidator {
    static func validate(origin: ShippingLabelAddress?, destination: ShippingLabelAddress?) -> Bool {
        usCountryISOCode.contains(origin?.country ?? "") && Country.EUCountryCodes.contains(destination?.country ?? "")
    }

    private static let usCountryISOCode: Set<String> = ["US", "USA"] // United States of America
}

extension Country {
    /// EU Country Code definitions.
    ///
    static let EUCountryCodes: Set<String> = ["AT", "AUT", // Austria
                                              "BE", "BEL", // Belgium
                                              "BG", "BGR", // Bulgaria
                                              "HR", "HRV", // Croatia
                                              "CY", "CYP", // Cyprus
                                              "CZ", "CZE", // Czech Republic
                                              "DK", "DNK", // Denmark
                                              "EE", "EST", // Estonia
                                              "FI", "FIN", // Finland
                                              "FR", "FRA", // France
                                              "DE", "DEU", // Germany
                                              "GR", "GRC", // Greece
                                              "HU", "HUN", // Hungary
                                              "IE", "IRL", // Ireland
                                              "IT", "ITA", // Italy
                                              "LV", "LVA", // Latvia
                                              "LT", "LTU", // Lithuania
                                              "LU", "LUX", // Luxembourg
                                              "MT", "MLT", // Malta
                                              "NL", "NLD", // Netherlands
                                              "NO", "NOR", // Norway
                                              "PL", "POL", // Poland
                                              "PT", "PRT", // Portugal
                                              "RO", "ROU", // Romania
                                              "SK", "SVK", // Slovakia
                                              "SI", "SVN", // Slovenia
                                              "ES", "ESP", // Spain
                                              "SE", "SWE", // Sweden
                                              "CH", "CHE"] // Switzerland

    /// GDPR Country Code definitions.
    /// *Although the UK has departed from the EU as of January 2021, the GDPR was enacted before its withdrawal and is therefore considered a valid UK law.*
    ///
    static let GDPRCountryCodes = EUCountryCodes + ["GB"]
}
