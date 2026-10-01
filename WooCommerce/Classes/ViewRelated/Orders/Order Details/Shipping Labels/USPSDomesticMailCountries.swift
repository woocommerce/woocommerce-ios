import WooFoundation

/// Countries in the USPS domestic mail path. Mirrors `USPSTerritories::DOMESTIC_MAIL_TERRITORIES`,
/// the source of truth in the WooCommerce Shipping plugin.
enum USPSDomesticMailCountries {
    static let countryCodes: Set<CountryCode> = [
        .US, // United States
        .PR, // Puerto Rico
        .VI, // Virgin Islands
        .GU, // Guam
        .AS, // American Samoa
        .UM, // United States Minor Outlying Islands
        .MH, // Marshall Islands
        .FM, // Micronesia
        .PW, // Palau
        .MP // Northern Mariana Islands
    ]

    /// Raw ISO 3166-1 alpha-2 codes for call sites that compare plain string country codes.
    static let rawCountryCodes: Set<String> = Set(countryCodes.map(\.rawValue))
}
