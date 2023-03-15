import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

final class CouponInputTransformerTests: XCTestCase {

    func test_new_input_adds_coupon_line_to_order() throws {
        // Given
        let order = Order.fake()
        let input = OrderCouponLine.fake().copy(code: "code")

        // When
        let updatedOrder = CouponInputTransformer.update(input: input, on: order)

        // Then
        let couponLine = try XCTUnwrap(updatedOrder.coupons.first)
        XCTAssertEqual(couponLine, input)
    }

    func test_new_input_updates_first_coupon_line_from_order() throws {
        // Given
        let coupon = OrderCouponLine.fake().copy(code: "code1")
        let coupon2 = OrderCouponLine.fake().copy(code: "code2")
        let order = Order.fake().copy(coupons: [coupon, coupon2])

        // When
        let input = OrderCouponLine.fake().copy(code: "codex")
        let updatedOrder = CouponInputTransformer.update(input: input, on: order)

        // Then
        let couponLine = try XCTUnwrap(updatedOrder.coupons.first)
        XCTAssertEqual(couponLine.code, input.code)
        XCTAssertEqual(couponLine.couponID, input.couponID)
        XCTAssertEqual(couponLine.discount, input.discount)
        XCTAssertEqual(couponLine.discountTax, input.discountTax)

        let couponLine2 = try XCTUnwrap(updatedOrder.coupons[safe: 1])
        XCTAssertEqual(coupon2, couponLine2)
    }

    func test_new_input_deletes_first_coupon_line_from_order() throws {
        // Given
        let coupon = OrderCouponLine.fake().copy(code: "code1")
        let coupon2 = OrderCouponLine.fake().copy(code: "code2")
        let order = Order.fake().copy(coupons: [coupon, coupon2])

        // When
        let updatedOrder = CouponInputTransformer.update(input: nil, on: order)

        // Then
        let couponLine = try XCTUnwrap(updatedOrder.coupons.first)
        XCTAssertEqual(couponLine.code, coupon2.code)
        XCTAssertEqual(couponLine.couponID, coupon2.couponID)
        XCTAssertEqual(couponLine.discount, coupon2.discount)
        XCTAssertEqual(couponLine.discountTax, coupon2.discountTax)

        XCTAssertEqual(updatedOrder.coupons.count, 1)
    }
}
