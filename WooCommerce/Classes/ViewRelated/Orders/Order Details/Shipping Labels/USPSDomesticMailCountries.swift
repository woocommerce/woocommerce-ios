import WooFoundation

/// Countries in the USPS domestic mail path — the store-origin and destination countries supported
/// for shipping label purchase with the Woo Shipping and legacy WCShip plugins.
/// This is hardcoded for now based on: https://git.io/JBuja.
/// It would be great if this can be fetched remotely.
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
        .MP // Northern Mariana Islands
    ]

    /// Raw ISO 3166-1 alpha-2 codes for call sites that compare plain string country codes.
    static let rawCountryCodes: Set<String> = Set(countryCodes.map(\.rawValue))
}
