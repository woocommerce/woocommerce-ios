import Foundation
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode

/// Validator for POS country and currency support.
///
/// Single source of truth for the supported country/currency pairings. The 13 expansion
/// countries (RSM-637) are accepted only when the supplied
/// ``CardPresentPaymentsCountryExpansionEligibilityServiceProtocol`` reports the site as
/// eligible. US/GB are always supported.
public enum POSCountryCurrencyValidator {
    /// Supported countries for POS feature.
    /// Always includes US and GB. The 13 expansion countries are added when the supplied
    /// eligibility service reports the site as eligible.
    public static func supportedCountries(
        siteID: Int64,
        eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
    ) -> [CountryCode] {
        var countries: [CountryCode] = [.US, .GB]
        if eligibilityService.isEligible(siteID: siteID) {
            countries.append(contentsOf: expansionCountries)
        }
        return countries
    }

    /// Supported currencies per country for POS feature.
    /// Always includes US/USD and GB/GBP. Expansion entries are added when the supplied
    /// eligibility service reports the site as eligible.
    public static func supportedCurrencies(
        siteID: Int64,
        eligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
    ) -> [CountryCode: [CurrencyCode]] {
        var map: [CountryCode: [CurrencyCode]] = [
            .US: [.USD],
            .GB: [.GBP]
        ]
        if eligibilityService.isEligible(siteID: siteID) {
            for country in eeaEuroCountries {
                map[country] = [.EUR]
            }
            map[.SG] = [.SGD]
            map[.NZ] = [.NZD]
        }
        return map
    }

    /// Validates if a country and currency combination is eligible for POS.
    /// - Parameters:
    ///   - countryCode: The store's country code.
    ///   - currencyCode: The store's currency code.
    ///   - siteID: The site ID, used to look up per-site expansion eligibility.
    ///   - eligibilityService: The cached expansion eligibility for this site.
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

    private static var expansionCountries: [CountryCode] {
        eeaEuroCountries + [.SG, .NZ]
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
