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
}
