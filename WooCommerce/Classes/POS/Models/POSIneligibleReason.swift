/// Represents the reasons why a site may be ineligible for POS.
enum POSIneligibleReason: Equatable {
    case unsupportedIOSVersion
    case unsupportedWooCommerceVersion(minimumVersion: String)
    case siteSettingsNotAvailable
    case wooCommercePluginNotFound
    case featureSwitchDisabled
    case unsupportedCurrency(countryCode: CountryCode, supportedCurrencies: [CurrencyCode])
    case selfDeallocated
}
