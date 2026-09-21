import Foundation
import Testing
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
@testable import Yosemite

@Suite("POSCountryCurrencyValidator Tests")
struct POSCountryCurrencyValidatorTests {
    // MARK: - Eligible Combinations (always-on)

    @Test("US with USD is eligible")
    func testUSWithUSDIsEligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .US,
                                                          currencyCode: .USD)
        #expect(result == .eligible)
    }

    @Test("GB with GBP is eligible")
    func testGBWithGBPIsEligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .GB,
                                                          currencyCode: .GBP)
        #expect(result == .eligible)
    }

    @Test("PR with USD is eligible without cached country eligibility")
    func test_PR_with_USD_is_eligible_without_cached_country_eligibility() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .PR,
                                                          currencyCode: .USD)
        #expect(result == .eligible)
    }

    @Test("CA with CAD is eligible without cached country eligibility")
    func testCAWithCADIsEligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .CA,
                                                          currencyCode: .CAD)

        #expect(result == .eligible)
    }

    @Test("AU with AUD is eligible")
    func testAUWithAUDIsEligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .AU,
                                                          currencyCode: .AUD)

        #expect(result == .eligible)
    }

    // MARK: - Unsupported Currencies for Supported Countries

    @Test("US with EUR is ineligible due to unsupported currency")
    func testUSWithEURIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .US,
                                                          currencyCode: .EUR)

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
                                                          currencyCode: .GBP)

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
                                                          currencyCode: .USD)

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
                                                          currencyCode: .EUR)

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

    @Test("CA with USD is ineligible due to unsupported currency")
    func testCAWithUSDIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .CA,
                                                          currencyCode: .USD)

        guard case .ineligible(let reason) = result else {
            Issue.record("Expected ineligible result")
            return
        }
        guard case .unsupportedCurrency(let countryCode, let supportedCurrencies) = reason else {
            Issue.record("Expected unsupportedCurrency reason")
            return
        }
        #expect(countryCode == .CA)
        #expect(supportedCurrencies == [.CAD])
    }

    // MARK: - Supported Countries List

    @Test("Supported countries list includes all launched countries")
    func testSupportedCountriesList() {
        let supportedCountries = POSCountryCurrencyValidator.supportedCountries
        #expect(supportedCountries == alwaysSupportedCountries)
    }

    // MARK: - Supported Currencies Map

    @Test("Supported currencies map includes all launched countries")
    func testSupportedCurrenciesMap() {
        let supportedCurrencies = POSCountryCurrencyValidator.supportedCurrencies

        #expect(supportedCurrencies[.US] == [.USD])
        #expect(supportedCurrencies[.PR] == [.USD])
        #expect(supportedCurrencies[.GB] == [.GBP])
        #expect(supportedCurrencies[.CA] == [.CAD])
        #expect(supportedCurrencies[.AT] == nil)
        #expect(supportedCurrencies[.DE] == nil)
        for country in eeaEuroCountries {
            #expect(supportedCurrencies[country] == [.EUR])
        }
        #expect(supportedCurrencies[.SG] == [.SGD])
        #expect(supportedCurrencies[.NZ] == [.NZD])
        #expect(supportedCurrencies[.AU] == [.AUD])
    }

    // MARK: - Expansion country behavior

    @Test(arguments: [
        (country: CountryCode.FI, currency: CurrencyCode.EUR),
        (country: CountryCode.IE, currency: CurrencyCode.EUR),
        (country: CountryCode.LU, currency: CurrencyCode.EUR),
        (country: CountryCode.NL, currency: CurrencyCode.EUR),
        (country: CountryCode.SG, currency: CurrencyCode.SGD),
        (country: CountryCode.NZ, currency: CurrencyCode.NZD),
        (country: CountryCode.AU, currency: CurrencyCode.AUD)
    ])
    func launched_expansion_country_with_local_currency_is_eligible(country: CountryCode, currency: CurrencyCode) {
        let result = POSCountryCurrencyValidator.validate(countryCode: country,
                                                          currencyCode: currency)
        #expect(result == .eligible)
    }

    @Test("Expansion country with mismatched currency is ineligible")
    func test_expansion_country_with_mismatched_currency_is_ineligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .FI,
                                                          currencyCode: .USD)
        #expect(result == .ineligible(reason: .unsupportedCurrency(countryCode: .FI, supportedCurrencies: [.EUR])))
    }

    @Test(arguments: [
        CountryCode.AT,
        .BE,
        .FR,
        .DE,
        .IT,
        .PT,
        .ES
    ])
    func fiscalization_country_is_unsupported_even_when_current_site_country_is_eligible(country: CountryCode) {
        let result = POSCountryCurrencyValidator.validate(countryCode: country,
                                                          currencyCode: .EUR)
        guard case .ineligible(let reason) = result, case .unsupportedCountry(let supportedCountries) = reason else {
            Issue.record("Expected unsupportedCountry result, got \(result)")
            return
        }
        #expect(!supportedCountries.contains(country))
    }

    private let eeaEuroCountries: [CountryCode] = [
        .FI, .IE, .LU, .NL
    ]

    private let alwaysSupportedCountries: [CountryCode] = [
        .US, .PR, .GB, .CA, .FI, .IE, .LU, .NL, .SG, .NZ, .AU
    ]
}
