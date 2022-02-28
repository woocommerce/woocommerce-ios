import Foundation
import XCTest
@testable import Yosemite

class CardPresentConfigurationTests: XCTestCase {
    // MARK: - US Tests
    func test_configuration_for_US_with_Canada_enabled() throws {
        let configuration = CardPresentPaymentsConfiguration(country: "US", canadaEnabled: true)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.usd])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(for: .wcPay).absoluteString, Constants.PurchaseURL.wcpay)
        XCTAssertEqual(configuration.purchaseCardReaderUrl(for: .stripe).absoluteString, Constants.PurchaseURL.stripe)
    }

    func test_configuration_for_US_with_Canada_disabled() throws {
        let configuration = CardPresentPaymentsConfiguration(country: "US", canadaEnabled: false)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.usd])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay, Constants.PaymentGateway.stripe])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(for: .wcPay).absoluteString, Constants.PurchaseURL.wcpay)
        XCTAssertEqual(configuration.purchaseCardReaderUrl(for: .stripe).absoluteString, Constants.PurchaseURL.stripe)
    }

    // MARK: - Canada Tests
    func test_configuration_for_Canada_with_Canada_enabled() throws {
        let configuration = CardPresentPaymentsConfiguration(country: "CA", canadaEnabled: true)
        XCTAssertTrue(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.currencies, [Constants.Currency.cad])
        XCTAssertEqual(configuration.paymentGateways, [Constants.PaymentGateway.wcpay])
        XCTAssertEqual(configuration.paymentMethods, [.cardPresent, .interacPresent])
        XCTAssertEqual(configuration.purchaseCardReaderUrl(for: .wcPay).absoluteString, Constants.PurchaseURL.wcpay)
        XCTAssertEqual(configuration.purchaseCardReaderUrl(for: .stripe).absoluteString, Constants.PurchaseURL.stripe)
    }

    func test_configuration_for_Canada_with_Canada_disabled() {
        let configuration = CardPresentPaymentsConfiguration(country: "CA", canadaEnabled: false)
        XCTAssertFalse(configuration.isSupportedCountry)
        XCTAssertEqual(configuration.purchaseCardReaderUrl(for: .wcPay).absoluteString, Constants.PurchaseURL.wcpay)
        XCTAssertEqual(configuration.purchaseCardReaderUrl(for: .stripe).absoluteString, Constants.PurchaseURL.stripe)
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

        enum PurchaseURL {
            /// This is the older URL format for ordering card  readers for WCPay stores
            ///
            static let wcpay = "https://woocommerce.com/products/m2-card-reader/"

            /// The new URL format (behind feature flag at the moment) directs users to a country specific page
            ///
            static let wcpayUS = "https://woocommerce.com/products/hardware/US"
            static let wcpayCA = "https://woocommerce.com/products/hardware/CA"

            /// Merchants using the Stripe extension should order their readers from Stripe directly
            ///
            static let stripe = "https://stripe.com/terminal/stripe-reader"
        }
    }
}
