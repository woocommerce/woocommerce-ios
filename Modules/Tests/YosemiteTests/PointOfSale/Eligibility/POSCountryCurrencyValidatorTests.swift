import Foundation
import Testing
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
@testable import Yosemite

@Suite("POSCountryCurrencyValidator Tests")
struct POSCountryCurrencyValidatorTests {
    private let siteID: Int64 = 42
    private let ineligibleService = StubExpansionEligibilityService(isEligible: false)
    private let eligibleService = StubExpansionEligibilityService(isEligible: true)

    // MARK: - Eligible Combinations (always-on)

    @Test("US with USD is eligible")
    func testUSWithUSDIsEligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .US,
                                                          currencyCode: .USD,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)
        #expect(result == .eligible)
    }

    @Test("GB with GBP is eligible")
    func testGBWithGBPIsEligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .GB,
                                                          currencyCode: .GBP,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)
        #expect(result == .eligible)
    }

    @Test("PR with USD is eligible without cached country eligibility")
    func test_PR_with_USD_is_eligible_without_cached_country_eligibility() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .PR,
                                                          currencyCode: .USD,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)
        #expect(result == .eligible)
    }

    // MARK: - Unsupported Countries (cached country eligibility off)

    @Test("CA with USD is ineligible due to unsupported country when cached country eligibility is off")
    func testCAWithUSDIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .CA,
                                                          currencyCode: .USD,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)

        guard case .ineligible(let reason) = result else {
            Issue.record("Expected ineligible result")
            return
        }
        guard case .unsupportedCountry(let supportedCountries) = reason else {
            Issue.record("Expected unsupportedCountry reason")
            return
        }
        #expect(supportedCountries.contains(.US))
        #expect(supportedCountries.contains(.GB))
        #expect(!supportedCountries.contains(.CA))
    }

    @Test("AU with AUD is ineligible due to unsupported country when cached country eligibility is off")
    func testAUWithAUDIsIneligibleWhenCachedCountryEligibilityOff() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .AU,
                                                          currencyCode: .AUD,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)

        guard case .ineligible(let reason) = result else {
            Issue.record("Expected ineligible result")
            return
        }
        guard case .unsupportedCountry = reason else {
            Issue.record("Expected unsupportedCountry reason")
            return
        }
    }

    @Test("AU with AUD is eligible when current-site country eligibility is cached")
    func testAUWithAUDIsEligibleWhenCurrentSiteCountryEligibilityIsCached() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .AU,
                                                          currencyCode: .AUD,
                                                          siteID: siteID,
                                                          eligibilityService: eligibleService)

        #expect(result == .eligible)
    }

    // MARK: - Unsupported Currencies for Supported Countries

    @Test("US with EUR is ineligible due to unsupported currency")
    func testUSWithEURIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .US,
                                                          currencyCode: .EUR,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)

        guard case .ineligible(let reason) = result else {
            Issue.record("Expected ineligible result")
            return
        }
        guard case .unsupportedCurrency(let countryCode, let supportedCurrencies) = reason else {
            Issue.record("Expected unsupportedCurrency reason")
            return
        }
        #expect(countryCode == .US)
        #expect(supportedCurrencies == [.USD])
    }

    @Test("US with GBP is ineligible due to unsupported currency")
    func testUSWithGBPIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .US,
                                                          currencyCode: .GBP,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)

        guard case .ineligible(let reason) = result else {
            Issue.record("Expected ineligible result")
            return
        }
        guard case .unsupportedCurrency(let countryCode, let supportedCurrencies) = reason else {
            Issue.record("Expected unsupportedCurrency reason")
            return
        }
        #expect(countryCode == .US)
        #expect(supportedCurrencies == [.USD])
    }

    @Test("GB with USD is ineligible due to unsupported currency")
    func testGBWithUSDIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .GB,
                                                          currencyCode: .USD,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)

        guard case .ineligible(let reason) = result else {
            Issue.record("Expected ineligible result")
            return
        }
        guard case .unsupportedCurrency(let countryCode, let supportedCurrencies) = reason else {
            Issue.record("Expected unsupportedCurrency reason")
            return
        }
        #expect(countryCode == .GB)
        #expect(supportedCurrencies == [.GBP])
    }

    @Test("GB with EUR is ineligible due to unsupported currency")
    func testGBWithEURIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .GB,
                                                          currencyCode: .EUR,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)

        guard case .ineligible(let reason) = result else {
            Issue.record("Expected ineligible result")
            return
        }
        guard case .unsupportedCurrency(let countryCode, let supportedCurrencies) = reason else {
            Issue.record("Expected unsupportedCurrency reason")
            return
        }
        #expect(countryCode == .GB)
        #expect(supportedCurrencies == [.GBP])
    }

    // MARK: - Supported Countries List

    @Test("Supported countries list contains only US, PR, and GB when cached country eligibility is off")
    func testSupportedCountriesList() {
        let supportedCountries = POSCountryCurrencyValidator.supportedCountries(siteID: siteID, eligibilityService: ineligibleService)
        #expect(supportedCountries.count == 3)
        #expect(supportedCountries.contains(.US))
        #expect(supportedCountries.contains(.PR))
        #expect(supportedCountries.contains(.GB))
    }

    @Test("Supported countries list includes the validator's gated-country set when the current site country is eligible")
    func testSupportedCountriesIncludeValidatorGatedCountrySetWhenCurrentSiteCountryEligible() {
        let supportedCountries = POSCountryCurrencyValidator.supportedCountries(siteID: siteID, eligibilityService: eligibleService)

        #expect(supportedCountries.contains(.US))
        #expect(supportedCountries.contains(.PR))
        #expect(supportedCountries.contains(.GB))
        for country in validatorGatedCountrySet {
            #expect(supportedCountries.contains(country), "Expected \(country) to be present in the validator's gated-country set")
        }
    }

    // MARK: - Supported Currencies Map

    @Test("Supported currencies map only contains US, PR, and GB entries when cached country eligibility is off")
    func testSupportedCurrenciesMap() {
        let supportedCurrencies = POSCountryCurrencyValidator.supportedCurrencies(siteID: siteID, eligibilityService: ineligibleService)

        #expect(supportedCurrencies[.US] == [.USD])
        #expect(supportedCurrencies[.PR] == [.USD])
        #expect(supportedCurrencies[.GB] == [.GBP])
        #expect(supportedCurrencies[.CA] == nil)
        #expect(supportedCurrencies[.AT] == nil)
        #expect(supportedCurrencies[.SG] == nil)
        #expect(supportedCurrencies[.NZ] == nil)
    }

    @Test("Supported currencies map includes the validator's gated-country entries when the current site country is eligible")
    func testSupportedCurrenciesMapIncludesValidatorGatedEntriesWhenCurrentSiteCountryEligible() {
        let supportedCurrencies = POSCountryCurrencyValidator.supportedCurrencies(siteID: siteID, eligibilityService: eligibleService)

        for country in eeaEuroCountries {
            #expect(supportedCurrencies[country] == [.EUR], "Expected \(country) to map to EUR in the validator's gated-country set")
        }
        #expect(supportedCurrencies[.SG] == [.SGD])
        #expect(supportedCurrencies[.NZ] == [.NZD])
        #expect(supportedCurrencies[.AU] == [.AUD])
    }

    // MARK: - Validator gated-country behavior

    @Test(arguments: [
        (country: CountryCode.AT, currency: CurrencyCode.EUR),
        (country: CountryCode.BE, currency: CurrencyCode.EUR),
        (country: CountryCode.FI, currency: CurrencyCode.EUR),
        (country: CountryCode.FR, currency: CurrencyCode.EUR),
        (country: CountryCode.DE, currency: CurrencyCode.EUR),
        (country: CountryCode.IE, currency: CurrencyCode.EUR),
        (country: CountryCode.IT, currency: CurrencyCode.EUR),
        (country: CountryCode.LU, currency: CurrencyCode.EUR),
        (country: CountryCode.NL, currency: CurrencyCode.EUR),
        (country: CountryCode.PT, currency: CurrencyCode.EUR),
        (country: CountryCode.ES, currency: CurrencyCode.EUR),
        (country: CountryCode.SG, currency: CurrencyCode.SGD),
        (country: CountryCode.NZ, currency: CurrencyCode.NZD),
        (country: CountryCode.AU, currency: CurrencyCode.AUD)
    ])
    func gated_country_with_local_currency_is_eligible_when_current_site_country_is_eligible(country: CountryCode, currency: CurrencyCode) {
        let result = POSCountryCurrencyValidator.validate(countryCode: country,
                                                          currencyCode: currency,
                                                          siteID: siteID,
                                                          eligibilityService: eligibleService)
        #expect(result == .eligible)
    }

    @Test("Gated country with mismatched currency is ineligible when the current site country is eligible")
    func test_gated_country_with_mismatched_currency_is_ineligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .DE,
                                                          currencyCode: .USD,
                                                          siteID: siteID,
                                                          eligibilityService: eligibleService)
        #expect(result == .ineligible(reason: .unsupportedCurrency(countryCode: .DE, supportedCurrencies: [.EUR])))
    }

    @Test("Gated country is unsupported when eligibility off")
    func test_gated_country_is_unsupported_when_eligibility_off() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .DE,
                                                          currencyCode: .EUR,
                                                          siteID: siteID,
                                                          eligibilityService: ineligibleService)
        guard case .ineligible(let reason) = result, case .unsupportedCountry = reason else {
            Issue.record("Expected unsupportedCountry result, got \(result)")
            return
        }
    }

    private let eeaEuroCountries: [CountryCode] = [
        .AT, .BE, .FI, .FR, .DE, .IE, .IT, .LU, .NL, .PT, .ES
    ]

    // Mirrors the validator's temporary coarse gated-country set. The specific
    // rollout flag is resolved by the refresher before the validator reads the
    // cached eligibility value.
    private var validatorGatedCountrySet: [CountryCode] {
        eeaEuroCountries + [.SG, .NZ, .AU]
    }
}

// MARK: - Test Helpers

private struct StubExpansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol {
    let isEligible: Bool

    func isEligible(siteID: Int64) -> Bool {
        isEligible
    }

    func cacheEligibility(siteID: Int64, isEligible: Bool) {
        // No-op; tests don't exercise caching here.
    }
}
