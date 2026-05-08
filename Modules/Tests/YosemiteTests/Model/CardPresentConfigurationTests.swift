import Foundation
import XCTest
@testable import Yosemite
import WooFoundation

class CardPresentConfigurationTests: XCTestCase {
    // MARK: - US Tests
    func test_configuration_for_US() throws {
        let configuration = CardPresentPaymentsConfiguration(country: .US)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.USD])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(utmProvider: MockUTMParameterProvider()).absoluteString, Constants.PurchaseURL.us)
        assertEqual([.chipper, .stripeM2, .tapToPay], configuration.supportedReaders)
    }

    // MARK: - Puerto Rico Tests
    func test_configuration_for_PR() throws {
        let configuration = CardPresentPaymentsConfiguration(country: .PR)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.USD])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.supportedPluginVersions, [.init(plugin: .wcPay, minimumVersion: "9.0.0")])
        assertEqual([.chipper, .stripeM2], configuration.supportedReaders)
        // The `purchaseCardReaderUrl` for PR doesn't exist. On lack of country code, the URL redirection falls back to the M2 reader
    }

    // MARK: - Canada Tests
    func test_configuration_for_Canada() throws {
        let configuration = CardPresentPaymentsConfiguration(country: .CA)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.CAD])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent, .interacPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(utmProvider: MockUTMParameterProvider()).absoluteString, Constants.PurchaseURL.ca)
        assertEqual([.wisepad3], configuration.supportedReaders)
        assertEqual(25000, configuration.contactlessLimitAmount)
    }

    // MARK: - United Kingdom Tests
    func test_configuration_for_United_Kingdom() throws {
        let configuration = CardPresentPaymentsConfiguration(country: .GB)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.GBP])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(utmProvider: MockUTMParameterProvider()).absoluteString, Constants.PurchaseURL.gb)
        assertEqual([.wisepad3, .tapToPay], configuration.supportedReaders)
        assertEqual(10000, configuration.contactlessLimitAmount)
    }

    // MARK: - Country Expansion (RSM-637)
    //
    // The model knows about all 13 expansion countries unconditionally; per-site exposure
    // is gated upstream by `CardPresentConfigurationLoader` + the eligibility cache.

    func test_configuration_for_each_EEA_Euro_expansion_country() {
        let eeaCountries: [CountryCode] = [.AT, .BE, .FI, .FR, .DE, .IE, .IT, .LU, .NL, .PT, .ES]
        for country in eeaCountries {
            let configuration = CardPresentPaymentsConfiguration(country: country)
            XCTAssertTrue(configuration.isSupportedCountry, "Expected \(country) to be supported by the model")
            XCTAssertEqual(configuration.currencies, [.EUR])
            XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
            XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
            XCTAssertEqual(configuration.supportedReaders, [.wisepad3])
            XCTAssertEqual(configuration.supportedPluginVersions, [
                .init(plugin: .wcPay, minimumVersion: "4.4.0"),
                .init(plugin: .stripe, minimumVersion: "6.2.0")
            ])
            XCTAssertEqual(configuration.minimumAllowedChargeAmount, NSDecimalNumber(string: "0.5"))
            // €50 — Stripe Terminal contactless CVM limit for EEA-Euro countries.
            XCTAssertEqual(configuration.contactlessLimitAmount, 5000)
            XCTAssertEqual(configuration.stripeSmallestCurrencyUnitMultiplier, 100)
        }
    }

    func test_configuration_for_Singapore() {
        let configuration = CardPresentPaymentsConfiguration(country: .SG)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.SGD])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.supportedReaders, [.wisepad3])
        XCTAssertEqual(configuration.minimumAllowedChargeAmount, NSDecimalNumber(string: "0.5"))
        // SG isn't in Stripe Terminal's published contactless limit table, so we leave it nil.
        XCTAssertNil(configuration.contactlessLimitAmount)
    }

    func test_configuration_for_New_Zealand() {
        let configuration = CardPresentPaymentsConfiguration(country: .NZ)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.NZD])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.supportedReaders, [.wisepad3])
        XCTAssertEqual(configuration.minimumAllowedChargeAmount, NSDecimalNumber(string: "0.5"))
        // NZD 200 — Stripe Terminal contactless CVM limit.
        XCTAssertEqual(configuration.contactlessLimitAmount, 20000)
    }

    func test_configuration_for_Australia() {
        let configuration = CardPresentPaymentsConfiguration(country: .AU)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.AUD])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.supportedReaders, [.wisepad3])
        XCTAssertEqual(configuration.supportedPluginVersions, [
            .init(plugin: .wcPay, minimumVersion: Constants.minimumWCPayVersionForTerminalPaymentPreparation),
            .init(plugin: .stripe, minimumVersion: "6.2.0")
        ])
        XCTAssertEqual(configuration.minimumAllowedChargeAmount, NSDecimalNumber(string: "0.5"))
        XCTAssertEqual(configuration.contactlessLimitAmount, 20000)
    }

    private enum Constants {

        enum PaymentGateway {
            static let wcpay = "woocommerce-payments"
            static let stripe = "woocommerce-stripe"
        }

        enum PurchaseURL {
            /// The URL format directs users to a country specific page
            ///
            static let us = "https://woocommerce.com/products/hardware/US?utm_medium=woo_ios"
            static let ca = "https://woocommerce.com/products/hardware/CA?utm_medium=woo_ios"
            static let gb = "https://woocommerce.com/products/hardware/GB?utm_medium=woo_ios"
        }

        static let minimumWCPayVersionForTerminalPaymentPreparation = "10.8.0-test-1"
    }
}
