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
        assertEqual([.chipper, .stripeM2, .appleBuiltIn], configuration.supportedReaders)
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
        let configuration = CardPresentPaymentsConfiguration(country: .GB, shouldAllowTapToPayInUK: true)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.GBP])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(utmProvider: MockUTMParameterProvider()).absoluteString, Constants.PurchaseURL.gb)
        assertEqual([.wisepad3, .appleBuiltIn], configuration.supportedReaders)
        assertEqual(10000, configuration.contactlessLimitAmount)
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
    }
}
