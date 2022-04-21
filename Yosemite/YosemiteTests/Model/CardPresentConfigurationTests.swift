import Foundation
import XCTest
@testable import Yosemite

class CardPresentConfigurationTests: XCTestCase {
    // MARK: - US Tests
    func test_configuration_for_US_with_Canada_enabled() throws {
        let configuration = CardPresentPaymentsConfiguration(country: "US", canadaEnabled: true)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.USD])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl().absoluteString, Constants.PurchaseURL.us)
    }

    func test_configuration_for_US_with_Canada_disabled() throws {
        let configuration = CardPresentPaymentsConfiguration(country: "US", canadaEnabled: false)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.USD])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl().absoluteString, Constants.PurchaseURL.us)
    }

    // MARK: - Canada Tests
    func test_configuration_for_Canada_with_Canada_enabled() throws {
        let configuration = CardPresentPaymentsConfiguration(country: "CA", canadaEnabled: true)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.CAD])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent, .interacPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl().absoluteString, Constants.PurchaseURL.ca)
    }

    func test_configuration_for_Canada_with_Canada_disabled() {
        let configuration = CardPresentPaymentsConfiguration(country: "CA", canadaEnabled: false)
        XCTAssertFalse(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.purchaseCardReaderUrl().absoluteString, Constants.PurchaseURL.ca)
    }

    private enum Constants {

        enum PaymentGateway {
            static let wcpay = "woocommerce-payments"
            static let stripe = "woocommerce-stripe"
        }

        enum PurchaseURL {
            /// The URL format directs users to a country specific page
            ///
            static let us = "https://woocommerce.com/products/hardware/US"
            static let ca = "https://woocommerce.com/products/hardware/CA"
        }
    }
}
