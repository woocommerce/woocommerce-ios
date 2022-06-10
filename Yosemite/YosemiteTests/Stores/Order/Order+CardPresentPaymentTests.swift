@testable import Yosemite

import Foundation
import XCTest

final class Order_CardPresentPaymentTests: XCTestCase {
    private static let currency = "USD"
    private static let country = "US"
    private let configuration = CardPresentPaymentsConfiguration(country: Order_CardPresentPaymentTests.country)
    private let eligibleOrder = Order.fake().copy(status: .pending,
                                               currency: Order_CardPresentPaymentTests.currency,
                                               datePaid: nil,
                                               total: "25",
                                               paymentMethodID: "woocommercePayments")

    func test_isEligibleForCardPresentPayment_when_order_has_all_requirements_then_it_is_eligible() {
        XCTAssertFalse(eligibleOrder.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: configuration, products: []))
    }

    func test_isEligibleForCardPresentPayment_when_order_has_date_paid_then_is_not_eligible() {
        // Given
        let order = eligibleOrder.copy(datePaid: Date())

        // Then
        XCTAssertFalse(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: configuration, products: []))
    }

    func test_isEligibleForCardPresentPayment_when_total_is_zero_then_is_not_eligible() {
        // Given
        let order = eligibleOrder.copy(total: "0")

        // Then
        XCTAssertFalse(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: configuration, products: []))
    }

    func test_isEligibleForCardPresentPayment_when_status_is_not_valid_then_is_not_eligible() {
        // Given
        let notEligibleStatuses: [OrderStatusEnum] = [.autoDraft, .completed, .cancelled, .refunded, .failed, .custom("test")]

        for notEligibleStatus in notEligibleStatuses {
            let order = eligibleOrder.copy(status: notEligibleStatus)
            XCTAssertFalse(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: configuration, products: []))
        }
    }

    func test_isEligibleForCardPresentPayment_when_payment_method_is_unknown_then_is_not_eligible() {
        // Given
        let order = eligibleOrder.copy(paymentMethodID: "unknown")

        // Then
        XCTAssertFalse(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: configuration, products: []))
    }

    func test_isEligibleForCardPresentPayment_when_currency_is_different_than_configuration_then_is_not_eligible() {
        // Given
        let order = eligibleOrder.copy(currency: "EUR")

        // Then
        XCTAssertFalse(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: configuration, products: []))
    }

    func test_isEligibleForCardPresentPayment_when_there_is_a_subscription_product_then_is_not_eligible() {
        // Given
        let productID: Int64 = 1
        let product = Product.fake().copy(productID: productID, productTypeKey: "subscription")
        let order = eligibleOrder.copy(items: [OrderItem.fake().copy(productID: productID)])

        // Then
        XCTAssertFalse(order.isEligibleForCardPresentPayment(cardPresentPaymentsConfiguration: configuration, products: [product]))
    }
}
