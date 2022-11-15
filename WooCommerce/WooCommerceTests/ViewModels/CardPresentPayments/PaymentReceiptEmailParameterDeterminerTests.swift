import XCTest
import TestKit
@testable import WooCommerce
@testable import Yosemite

final class PaymentReceiptEmailParameterDeterminerTests: XCTestCase {
    func test_when_only_WCPay_is_active_and_version_is_higher_than_minimum_that_sends_email_then_returns_nil() {
        // Given
        let order = Order.fake()
        let wcPayPlugin = SystemPlugin.fake().copy(version: "4.3.4")
        let cardPresentPluginsDataProvider = MockCardPresentPluginsDataProvider(wcPayPlugin: wcPayPlugin,
                                                                                paymentPluginsInstalledAndActiveStatus: .onlyWCPayIsInstalledAndActive)
        let sut = PaymentReceiptEmailParameterDeterminer(cardPresentPluginsDataProvider: cardPresentPluginsDataProvider)

        // When
        let email = sut.receiptEmail(from: order)

        // Then
        XCTAssertNil(email)
    }

    func test_when_only_WCPay_is_active_and_version_is_equal_to_minimum_that_sends_email_then_returns_nil() {
        // Given
        let receiptEmail = "test@test.com"
        let billingAddress = Address.fake().copy(email: receiptEmail)
        let wcPayPlugin = SystemPlugin.fake().copy(version: "4.0.0")
        let cardPresentPluginsDataProvider = MockCardPresentPluginsDataProvider(wcPayPlugin: wcPayPlugin,
                                                                                paymentPluginsInstalledAndActiveStatus: .onlyWCPayIsInstalledAndActive)
        let sut = PaymentReceiptEmailParameterDeterminer(cardPresentPluginsDataProvider: cardPresentPluginsDataProvider)

        // When
        let email = sut.receiptEmail(from: Order.fake().copy(billingAddress: billingAddress))

        // Then
        XCTAssertNil(email)
    }

    func test_when_only_WCPay_is_active_and_version_is_lower_than_minimum_that_sends_email_then_returns_order_email() {
        // Given
        let receiptEmail = "test@test.com"
        let billingAddress = Address.fake().copy(email: receiptEmail)
        let wcPayPlugin = SystemPlugin.fake().copy(version: "3.9.9")
        let cardPresentPluginsDataProvider = MockCardPresentPluginsDataProvider(wcPayPlugin: wcPayPlugin,
                                                                                paymentPluginsInstalledAndActiveStatus: .onlyWCPayIsInstalledAndActive)
        let sut = PaymentReceiptEmailParameterDeterminer(cardPresentPluginsDataProvider: cardPresentPluginsDataProvider)

        // When
        let returnedEmail = sut.receiptEmail(from: Order.fake().copy(billingAddress: billingAddress))

        // Then
        XCTAssertEqual(returnedEmail, receiptEmail)
    }

    func test_when_WCPay_and_Stripe_are_both_installed_and_active_then_returns_nil() {
        // Given
        let receiptEmail = "test@test.com"
        let billingAddress = Address.fake().copy(email: receiptEmail)
        let cardPresentPluginsDataProvider = MockCardPresentPluginsDataProvider(paymentPluginsInstalledAndActiveStatus: .bothAreInstalledAndActive)
        let sut = PaymentReceiptEmailParameterDeterminer(cardPresentPluginsDataProvider: cardPresentPluginsDataProvider)

        // When
        let email = sut.receiptEmail(from: Order.fake().copy(billingAddress: billingAddress))

        // Then
        XCTAssertNil(email)
    }

    func test_when_WCPay_is_not_active_then_returns_email() {
        // Given
        let receiptEmail = "test@test.com"
        let billingAddress = Address.fake().copy(email: receiptEmail)
        let cardPresentPluginsDataProvider = MockCardPresentPluginsDataProvider(paymentPluginsInstalledAndActiveStatus: .onlyStripeIsInstalledAndActive)
        let sut = PaymentReceiptEmailParameterDeterminer(cardPresentPluginsDataProvider: cardPresentPluginsDataProvider)

        // When
        let returnedEmail = sut.receiptEmail(from: Order.fake().copy(billingAddress: billingAddress))

        // Then
        XCTAssertEqual(returnedEmail, receiptEmail)
    }
}
