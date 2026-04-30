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

    // MARK: - Unsupported Countries (eligibility off)

    @Test("CA with USD is ineligible due to unsupported country when expansion eligibility off")
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

    @Test("AU with AUD is ineligible due to unsupported country")
    func testAUWithAUDIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .AU,
                                                          currencyCode: .AUD,
                                                          siteID: siteID,
                                                          eligibilityService: eligibleService)

        guard case .ineligible(let reason) = result else {
            Issue.record("Expected ineligible result")
            return
        }
        guard case .unsupportedCountry = reason else {
            Issue.record("Expected unsupportedCountry reason")
            return
        }
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

    @Test("Supported countries list contains only US and GB when expansion eligibility off")
    func testSupportedCountriesList() {
        let supportedCountries = POSCountryCurrencyValidator.supportedCountries(siteID: siteID, eligibilityService: ineligibleService)
        #expect(supportedCountries.count == 2)
        #expect(supportedCountries.contains(.US))
        #expect(supportedCountries.contains(.GB))
    }

    @Test("Supported countries list contains all 15 countries when expansion eligibility on")
    func testSupportedCountriesIncludeExpansionCountriesWhenEligibilityOn() {
        let supportedCountries = POSCountryCurrencyValidator.supportedCountries(siteID: siteID, eligibilityService: eligibleService)

        #expect(supportedCountries.contains(.US))
        #expect(supportedCountries.contains(.GB))
        for country in expansionCountries {
            #expect(supportedCountries.contains(country), "Expected \(country) to be supported when eligibility is on")
        }
        // Australia is intentionally excluded pending EFTPOS support (RSM-642/643)
        #expect(!supportedCountries.contains(.AU))
    }

    // MARK: - Supported Currencies Map

    @Test("Supported currencies map only contains US and GB entries when expansion eligibility off")
    func testSupportedCurrenciesMap() {
        let supportedCurrencies = POSCountryCurrencyValidator.supportedCurrencies(siteID: siteID, eligibilityService: ineligibleService)

        #expect(supportedCurrencies[.US] == [.USD])
        #expect(supportedCurrencies[.GB] == [.GBP])
        #expect(supportedCurrencies[.CA] == nil)
        #expect(supportedCurrencies[.AT] == nil)
        #expect(supportedCurrencies[.SG] == nil)
        #expect(supportedCurrencies[.NZ] == nil)
    }

    @Test("Supported currencies map includes EUR/SGD/NZD entries when expansion eligibility on")
    func testSupportedCurrenciesMapIncludesExpansionEntriesWhenEligibilityOn() {
        let supportedCurrencies = POSCountryCurrencyValidator.supportedCurrencies(siteID: siteID, eligibilityService: eligibleService)

        for country in eeaEuroCountries {
            #expect(supportedCurrencies[country] == [.EUR], "Expected \(country) to map to EUR when eligibility is on")
        }
        #expect(supportedCurrencies[.SG] == [.SGD])
        #expect(supportedCurrencies[.NZ] == [.NZD])
        #expect(supportedCurrencies[.AU] == nil)
    }

    // MARK: - Country Expansion (eligibility on)

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
        (country: CountryCode.NZ, currency: CurrencyCode.NZD)
    ])
    func expansion_country_with_local_currency_is_eligible_when_eligibility_on(country: CountryCode, currency: CurrencyCode) {
        let result = POSCountryCurrencyValidator.validate(countryCode: country,
                                                          currencyCode: currency,
                                                          siteID: siteID,
                                                          eligibilityService: eligibleService)
        #expect(result == .eligible)
    }

    @Test("Expansion country with mismatched currency is ineligible when eligibility on")
    func test_expansion_country_with_mismatched_currency_is_ineligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .DE,
                                                          currencyCode: .USD,
                                                          siteID: siteID,
                                                          eligibilityService: eligibleService)
        #expect(result == .ineligible(reason: .unsupportedCurrency(countryCode: .DE, supportedCurrencies: [.EUR])))
    }

    @Test("Expansion country is unsupported when eligibility off")
    func test_expansion_country_is_unsupported_when_eligibility_off() {
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

    private var expansionCountries: [CountryCode] {
        eeaEuroCountries + [.SG, .NZ]
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
