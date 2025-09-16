import Foundation
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode

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

/// Represents the eligibility state for POS.
enum POSEligibilityState: Equatable {
    case eligible
    case ineligible(reason: POSIneligibleReason)
}
