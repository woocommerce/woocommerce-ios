import XCTest
import TestKit
import Fakes

@testable import WooCommerce
@testable import Yosemite

final class CouponInputTransformerTests: XCTestCase {

    func test_append_adds_coupon_line_to_order() throws {
        // Given
        let order = Order.fake()
        let input = "code"

        // When
        let updatedOrder = CouponInputTransformer.append(input: input, on: order)

        // Then
        let couponLine = try XCTUnwrap(updatedOrder.coupons.first)
        XCTAssertEqual(couponLine.code, input)
    }

    func test_remove_remove_coupon_line_from_order() throws {
        // Given
        let coupon = OrderCouponLine.fake().copy(code: "code1")
        let coupon2 = OrderCouponLine.fake().copy(code: "code2")
        let order = Order.fake().copy(coupons: [coupon, coupon2])

        // When
        let updatedOrder = CouponInputTransformer.remove(code: coupon.code, from: order)

        // Then
        let couponLine = try XCTUnwrap(updatedOrder.coupons.first)
        XCTAssertEqual(couponLine, coupon2)
        XCTAssertEqual(updatedOrder.coupons.count, 1)
    }
}
