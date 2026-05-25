import Foundation
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode

/// Validator for POS country and currency support.
///
/// Single source of truth for the supported country/currency pairings. Callers
/// are expected to refresh the per-site gated-country eligibility cache for the
/// current store country before validating. While the country-expansion flags
/// are temporary, the cache is a coarse per-site Boolean: the refresher decides
/// which remote flag controls the current store country, then this validator
/// applies the cached result to the set of countries that are still gated.
/// US/PR/GB are always supported.
public enum POSCountryCurrencyValidator {
    /// Supported countries for POS feature.
    /// Always includes US, PR, and GB. Gated countries are added when the supplied
    /// eligibility service reports the current site country as eligible.
    public static func supportedCountries(
        siteID: Int64,
        eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
    ) -> [CountryCode] {
        var countries: [CountryCode] = [.US, .PR, .GB]
        if eligibilityService.isEligible(siteID: siteID) {
            countries.append(contentsOf: remoteFlagGatedCountries)
        }
        return countries
    }

    /// Supported currencies per country for POS feature.
    /// Always includes US/USD, PR/USD, and GB/GBP. Gated entries are added when the supplied
    /// eligibility service reports the current site country as eligible.
    public static func supportedCurrencies(
        siteID: Int64,
        eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
    ) -> [CountryCode: [CurrencyCode]] {
        var map: [CountryCode: [CurrencyCode]] = [
            .US: [.USD],
            .PR: [.USD],
            .GB: [.GBP]
        ]
        if eligibilityService.isEligible(siteID: siteID) {
            for country in eeaEuroCountries {
                map[country] = [.EUR]
            }
            map[.SG] = [.SGD]
            map[.NZ] = [.NZD]
            map[.AU] = [.AUD]
        }
        return map
    }

    /// Validates if a country and currency combination is eligible for POS.
    /// - Parameters:
    ///   - countryCode: The store's country code.
    ///   - currencyCode: The store's currency code.
    ///   - siteID: The site ID, used to look up per-site gated-country eligibility.
    ///   - eligibilityService: The cached gated-country eligibility for this site.
    /// - Returns: Eligibility state with reason if ineligible.
    public static func validate(
        countryCode: CountryCode,
        currencyCode: CurrencyCode,
        siteID: Int64,
        eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
    ) -> ValidationResult {
        let supportedCountries = self.supportedCountries(siteID: siteID, eligibilityService: eligibilityService)
        // Check country first
        guard supportedCountries.contains(countryCode) else {
            return .ineligible(reason: .unsupportedCountry(supportedCountries: supportedCountries))
        }

        // Check currency for the country
        let supportedCurrenciesForCountry = supportedCurrencies(siteID: siteID, eligibilityService: eligibilityService)[countryCode] ?? []
        guard supportedCurrenciesForCountry.contains(currencyCode) else {
            return .ineligible(reason: .unsupportedCurrency(countryCode: countryCode, supportedCurrencies: supportedCurrenciesForCountry))
        }

        return .eligible
    }

    private static let eeaEuroCountries: [CountryCode] = [
        .AT, .BE, .FI, .FR, .DE, .IE, .IT, .LU, .NL, .PT, .ES
    ]

    /// Countries whose POS eligibility is still controlled by remote rollout
    /// flags. The specific flag is resolved before this validator is called.
    private static var remoteFlagGatedCountries: [CountryCode] {
        eeaEuroCountries + [.SG, .NZ, .AU]
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
