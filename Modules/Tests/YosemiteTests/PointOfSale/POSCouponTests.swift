import Fakes
import Foundation
import Testing
@testable import Yosemite

struct POSCouponTests {
    @Test func test_isExpired_when_no_expiration_date_then_returns_false() {
        // Given
        let coupon = POSCoupon(id: POSItemIdentifier(underlyingType: .product, itemID: 1), code: "valid-forever")

        // Then
        #expect(coupon.isExpired == false)
    }

    @Test func test_isExpired_when_future_date_then_returns_false() {
        // Given
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let coupon = POSCoupon(id: POSItemIdentifier(underlyingType: .product, itemID: 1), code: "will-expire-in-the-future", dateExpires: tomorrow)

        // Then
        #expect(coupon.isExpired == false)
    }

    @Test func test_isExpired_when_past_date_then_returns_true() {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let coupon = POSCoupon(id: POSItemIdentifier(underlyingType: .product, itemID: 1), code: "expired-yesterday", dateExpires: yesterday)

        // Then
        #expect(coupon.isExpired == true)
    }

    @Test func test_isExpired_when_current_date_then_returns_true() {
        // Given
        let now = Date()
        let coupon = POSCoupon(id: POSItemIdentifier(underlyingType: .product, itemID: 1), code: "expired-now", dateExpires: now)

        // Then
        #expect(coupon.isExpired == true, "A coupon expiring at the current time should be considered expired")
    }

    @Test(arguments: [Coupon.DiscountType.percent, .fixedCart])
    func test_appliesToWholeCart_when_cart_wide_type_and_no_restrictions_then_returns_true(discountType: Coupon.DiscountType) {
        // Given
        let coupon = Coupon.fake().copy(discountType: discountType, productIds: [], productCategories: [])

        // Then
        #expect(coupon.appliesToWholeCart == true)
    }

    @Test(arguments: [Coupon.DiscountType.fixedProduct, .other])
    func test_appliesToWholeCart_when_product_scoped_type_then_returns_false(discountType: Coupon.DiscountType) {
        // Given
        let coupon = Coupon.fake().copy(discountType: discountType, productIds: [], productCategories: [])

        // Then
        #expect(coupon.appliesToWholeCart == false)
    }

    @Test func test_appliesToWholeCart_when_restricted_to_products_then_returns_false() {
        // Given
        let coupon = Coupon.fake().copy(discountType: .percent, productIds: [42], productCategories: [])

        // Then
        #expect(coupon.appliesToWholeCart == false)
    }

    @Test func test_appliesToWholeCart_when_restricted_to_categories_then_returns_false() {
        // Given
        let coupon = Coupon.fake().copy(discountType: .fixedCart, productIds: [], productCategories: [7])

        // Then
        #expect(coupon.appliesToWholeCart == false)
    }
}
