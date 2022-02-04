import Foundation
import XCTest
@testable import Yosemite

class CardPresentConfigurationTests: XCTestCase {
    // MARK: - US Tests
    func testConfigurationForUsWithStripeEnabledCanadaEnabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "US", stripeEnabled: true, canadaEnabled: true)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.usd])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
    }

    func testConfigurationForUsWithStripeEnabledCanadaDisabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "US", stripeEnabled: true, canadaEnabled: false)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.usd])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
    }

    func testConfigurationForUsWithStripeDisabledCanadaEnabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "US", stripeEnabled: false, canadaEnabled: true)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.usd])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
    }

    func testConfigurationForUsWithStripeDisabledCanadaDisabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "US", stripeEnabled: false, canadaEnabled: false)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.usd])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
    }

    // MARK: - Canada Tests
    func testConfigurationForCanadaWithStripeEnabledCanadaEnabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "CA", stripeEnabled: true, canadaEnabled: true)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.cad])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent, .interacPresent])
    }

    func testConfigurationForCanadaWithStripeEnabledCanadaDisabled() {
        XCTAssertThrowsError(try CardPresentPaymentsConfiguration(country: "CA", stripeEnabled: true, canadaEnabled: false))
    }

    func testConfigurationForCanadaWithStripeDisabledCanadaEnabled() throws {
        let configuration = try CardPresentPaymentsConfiguration(country: "CA", stripeEnabled: false, canadaEnabled: true)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.cad])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent, .interacPresent])
    }

    func testConfigurationForCanadaWithStripeDisabledCanadaDisabled() throws {
        XCTAssertThrowsError(try CardPresentPaymentsConfiguration(country: "CA", stripeEnabled: false, canadaEnabled: false))
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
