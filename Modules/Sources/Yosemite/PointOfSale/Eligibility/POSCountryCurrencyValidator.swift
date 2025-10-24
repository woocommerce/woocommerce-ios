import Foundation
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode

/// Validator for POS country and currency support
/// Single source of truth for supported countries and currencies
public enum POSCountryCurrencyValidator {
    /// Supported countries for POS feature
    public static let supportedCountries: [CountryCode] = [.US, .GB]

    /// Supported currencies per country for POS feature
    public static let supportedCurrencies: [CountryCode: [CurrencyCode]] = [
        .US: [.USD],
        .GB: [.GBP]
    ]

    /// Validates if a country and currency combination is eligible for POS
    /// - Parameters:
    ///   - countryCode: The store's country code
    ///   - currencyCode: The store's currency code
    /// - Returns: Eligibility state with reason if ineligible
    public static func validate(countryCode: CountryCode, currencyCode: CurrencyCode) -> ValidationResult {
        // Check country first
        guard supportedCountries.contains(countryCode) else {
            return .ineligible(reason: .unsupportedCountry(supportedCountries: supportedCountries))
        }

        // Check currency for the country
        let supportedCurrenciesForCountry = supportedCurrencies[countryCode] ?? []
        guard supportedCurrenciesForCountry.contains(currencyCode) else {
            return .ineligible(reason: .unsupportedCurrency(countryCode: countryCode, supportedCurrencies: supportedCurrenciesForCountry))
        }

        return .eligible
    }
}

// MARK: - Validation Result

public extension POSCountryCurrencyValidator {
    enum ValidationResult: Equatable {
        case eligible
        case ineligible(reason: IneligibleReason)
    }

    enum IneligibleReason: Equatable {
        case unsupportedCountry(supportedCountries: [CountryCode])
        case unsupportedCurrency(countryCode: CountryCode, supportedCurrencies: [CurrencyCode])
    }
}
