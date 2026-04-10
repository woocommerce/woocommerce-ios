import Foundation
import Testing
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
@testable import Yosemite

@Suite("POSCountryCurrencyValidator Tests")
struct POSCountryCurrencyValidatorTests {

    // MARK: - Eligible Combinations

    @Test("US with USD is eligible")
    func testUSWithUSDIsEligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .US, currencyCode: .USD)
        #expect(result == .eligible)
    }

    @Test("GB with GBP is eligible")
    func testGBWithGBPIsEligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .GB, currencyCode: .GBP)
        #expect(result == .eligible)
    }

    // MARK: - Unsupported Countries

    @Test("CA with USD is ineligible due to unsupported country")
    func testCAWithUSDIsIneligible() {
        let result = POSCountryCurrencyValidator.validate(countryCode: .CA, currencyCode: .USD)

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
        let result = POSCountryCurrencyValidator.validate(countryCode: .AU, currencyCode: .AUD)

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
        let result = POSCountryCurrencyValidator.validate(countryCode: .US, currencyCode: .EUR)

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
        let result = POSCountryCurrencyValidator.validate(countryCode: .US, currencyCode: .GBP)

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
        let result = POSCountryCurrencyValidator.validate(countryCode: .GB, currencyCode: .USD)

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
        let result = POSCountryCurrencyValidator.validate(countryCode: .GB, currencyCode: .EUR)

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

    @Test("Supported countries list contains US and GB")
    func testSupportedCountriesList() {
        let supportedCountries = POSCountryCurrencyValidator.supportedCountries
        #expect(supportedCountries.count == 2)
        #expect(supportedCountries.contains(.US))
        #expect(supportedCountries.contains(.GB))
    }

    // MARK: - Supported Currencies Map

    @Test("Supported currencies map has correct structure")
    func testSupportedCurrenciesMap() {
        let supportedCurrencies = POSCountryCurrencyValidator.supportedCurrencies

        #expect(supportedCurrencies[.US] == [.USD])
        #expect(supportedCurrencies[.GB] == [.GBP])
        #expect(supportedCurrencies[.CA] == nil)
    }
}
