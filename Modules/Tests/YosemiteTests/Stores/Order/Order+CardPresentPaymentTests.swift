@testable import Yosemite

import Foundation
import XCTest
import WooFoundation

final class Order_CardPresentPaymentTests: XCTestCase {
    private static let currency = "USD"
    private static let country = CountryCode.US
    private let configuration = CardPresentPaymentsConfiguration(country: Order_CardPresentPaymentTests.country)
    private let eligibleOrder = Order.fake().copy(status: .pending,
                                               currency: Order_CardPresentPaymentTests.currency,
                                               datePaid: nil,
                                               total: "25",
                                               paymentMethodID: "woocommerce_payments")

    func test_eligibility_when_order_has_all_requirements_then_it_is_eligible() {
        XCTAssertEqual(eligibleOrder.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: []), .eligible)
    }

    func test_eligibility_when_order_has_date_paid_then_is_not_eligible() {
        // Given
        let order = eligibleOrder.copy(datePaid: Date())

        // Then
        XCTAssertEqual(order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: []), .ineligible)
    }

    func test_eligibility_when_total_is_zero_then_is_not_eligible() {
        // Given
        let order = eligibleOrder.copy(total: "0")

        // Then
        XCTAssertEqual(order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: []), .ineligible)
    }

    func test_eligibility_when_status_is_not_valid_then_is_not_eligible() {
        // Given
        let notEligibleStatuses: [OrderStatusEnum] = [.autoDraft, .completed, .cancelled, .refunded, .custom("test")]

        for notEligibleStatus in notEligibleStatuses {
            let order = eligibleOrder.copy(status: notEligibleStatus)
            XCTAssertEqual(order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: []), .ineligible)
        }
    }

    func test_eligibility_when_payment_method_is_unknown_then_is_not_eligible() {
        // Given
        let order = eligibleOrder.copy(paymentMethodID: "unknown")

        // Then
        XCTAssertEqual(order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: []), .ineligible)
    }

    func test_eligibility_when_there_is_a_subscription_product_then_is_not_eligible() {
        // Given
        let productID: Int64 = 1
        let product = Product.fake().copy(productID: productID, productTypeKey: "subscription")
        let order = eligibleOrder.copy(items: [OrderItem.fake().copy(productID: productID)])

        // Then
        XCTAssertEqual(order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: [product]), .ineligible)
    }

    func test_eligibility_when_only_currency_is_unsupported_then_returns_currency_reason() {
        for currency in ["EUR", "eur"] {
            // Given
            let order = eligibleOrder.copy(currency: currency)

            // When
            let result = order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: [])

            // Then
            XCTAssertEqual(result, .unsupportedCurrency("EUR"))
        }
    }

    func test_eligibility_when_order_is_paid_then_does_not_report_currency_as_the_reason() {
        // Given
        let order = eligibleOrder.copy(currency: "EUR", datePaid: Date())

        // When
        let result = order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: [])

        // Then
        XCTAssertEqual(result, .ineligible)
    }

    func test_eligibility_when_order_contains_subscription_then_does_not_report_currency_as_the_reason() {
        // Given
        let order = eligibleOrder.copy(currency: "EUR")
        let product = Product.fake().copy(productTypeKey: "subscription")

        // When
        let result = order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: [product])

        // Then
        XCTAssertEqual(result, .ineligible)
    }

    func test_eligibility_when_country_is_unresolved_or_unsupported_then_does_not_report_currency_as_the_reason() {
        // Given
        let countries: [CountryCode] = [.unknown, .LT]

        for country in countries {
            // When
            let result = eligibleOrder.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: .init(country: country), products: [])

            // Then
            XCTAssertEqual(result, .ineligible)
        }
    }

    func test_eligibility_when_currency_uses_lowercase_then_remains_eligible() {
        // Given
        let order = eligibleOrder.copy(currency: "usd")

        // When
        let result = order.cardPresentPaymentEligibility(cardPresentPaymentsConfiguration: configuration, products: [])

        // Then
        XCTAssertEqual(result, .eligible)
    }
}
