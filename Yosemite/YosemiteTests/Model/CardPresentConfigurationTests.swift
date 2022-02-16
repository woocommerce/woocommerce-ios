import Foundation
import XCTest
@testable import Yosemite

class CardPresentConfigurationTests: XCTestCase {
    // MARK: - US Tests
    func test_configuration_for_US_with_Canada_enabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "US", canadaEnabled: true)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.usd])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
    }

    func test_configuration_for_US_with_Canada_disabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "US", canadaEnabled: false)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.usd])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
    }

    // MARK: - Canada Tests
    func test_configuration_for_Canada_with_Canada_enabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "CA", canadaEnabled: true)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.cad])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent, .interacPresent])
    }

    func test_configuration_for_Canada_with_Canada_disabled() {
        XCTAssertThrowsError(try CardPresentPaymentsConfiguration(country: "CA", canadaEnabled: false))
    }

    private enum Constants {
        enum Currency {
            static let usd = "USD"
            static let cad = "CAD"
        }

        enum PaymentGateway {
            static let wcpay = "woocommerce-payments"
            static let stripe = "woocommerce-stripe"
        }
    }
}
