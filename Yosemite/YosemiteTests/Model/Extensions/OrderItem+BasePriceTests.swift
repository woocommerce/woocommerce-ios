import Foundation
import XCTest
import Networking
@testable import Yosemite

final class OrderItemBasePriceTests: XCTestCase {
    func test_base_price_when_zero_quantity_then_zero() {
        let item = OrderItem.fake().copy(quantity: 0, subtotal: "100.00")

        XCTAssertEqual(item.basePrice, NSDecimalNumber.zero)
    }

    func test_base_price_when_valid_subtotal_then_correct_calculation() {
        let item = OrderItem.fake().copy(quantity: 3, subtotal: "123.45")

        let expectedPrice = NSDecimalNumber(decimal: Decimal(41.15))

        XCTAssertEqual(item.basePrice, expectedPrice)
    }

    func test_base_price_when_valid_subtotal_alternative_separator_then_correct_calculation() {
        let item = OrderItem.fake().copy(quantity: 3, subtotal: "123,45")

        let expectedPrice = NSDecimalNumber(decimal: Decimal(41.15))

        XCTAssertEqual(item.basePrice, expectedPrice)
    }

    func test_base_price_when_invalid_subtotal_then_zero() {
        let item = OrderItem.fake().copy(quantity: 1, subtotal: "abc")

        XCTAssertEqual(item.basePrice, NSDecimalNumber.zero)
    }
}
