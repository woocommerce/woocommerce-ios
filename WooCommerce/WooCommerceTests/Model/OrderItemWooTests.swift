import Foundation
import XCTest
import Networking
@testable import WooCommerce

final class OrderItemWooTests: XCTestCase {
    func test_price_pre_discount_when_zero_quantity_then_zero() {
        let item = OrderItem.fake().copy(quantity: 0, subtotal: "100.00")

        XCTAssertEqual(item.pricePreDiscount, NSDecimalNumber.zero)
    }

    func test_price_pre_discount_when_valid_subtotal_then_correct_calculation() {
        let item = OrderItem.fake().copy(quantity: 3, subtotal: "123.45")

        let expectedPrice = NSDecimalNumber(decimal: Decimal(41.15))

        XCTAssertEqual(item.pricePreDiscount, expectedPrice)
    }

    func test_price_pre_discount_when_valid_subtotal_alternative_separator_then_correct_calculation() {
        let item = OrderItem.fake().copy(quantity: 3, subtotal: "123,45")

        let expectedPrice = NSDecimalNumber(decimal: Decimal(41.15))

        XCTAssertEqual(item.pricePreDiscount, expectedPrice)
    }

    func test_price_pre_discount_when_invalid_subtotal_then_zero() {
        let item = OrderItem.fake().copy(quantity: 1, subtotal: "abc")

        XCTAssertEqual(item.pricePreDiscount, NSDecimalNumber.zero)
    }
}
