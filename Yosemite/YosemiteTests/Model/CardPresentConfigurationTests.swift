import Foundation
import XCTest
@testable import Yosemite
import WooFoundation

class CardPresentConfigurationTests: XCTestCase {
    // MARK: - US Tests
    func test_configuration_for_US() throws {
        let configuration = CardPresentPaymentsConfiguration(country: "US")
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.USD])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(utmProvider: MockUTMParameterProvider()).absoluteString, Constants.PurchaseURL.us)
    }

    // MARK: - Canada Tests
    func test_configuration_for_Canada() throws {
        let configuration = CardPresentPaymentsConfiguration(country: "CA")
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [.CAD])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent, .interacPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(utmProvider: MockUTMParameterProvider()).absoluteString, Constants.PurchaseURL.ca)
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
        }
    }
}
