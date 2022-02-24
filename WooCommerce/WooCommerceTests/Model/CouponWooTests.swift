import XCTest
@testable import Networking
@testable import WooCommerce

final class CouponWooTests: XCTestCase {
    func test_expiry_status_is_active_if_dateExpires_is_undefined() {
        // Given
        let coupon = Coupon.fake().copy(dateExpires: nil)

        // Then
        XCTAssertEqual(coupon.expiryStatus(), .active)
    }

    func test_expiry_status_is_active_if_dateExpires_is_later_than_current_date() {
        // Given
        // GMT: Monday, February 21, 2022 5:00:00 PM
        let expiryDate = Date(timeIntervalSince1970: 1645462800)
        // GMT: Monday, February 21, 2022 11:01:36 AM
        let now = Date(timeIntervalSince1970: 1645441296)
        let coupon = Coupon.fake().copy(dateExpires: expiryDate)

        // Then
        XCTAssertEqual(coupon.expiryStatus(now: now), .active)
    }

    func test_expiry_status_is_expired_if_dateExpires_is_earlier_than_current_date() {
        // Given
        // GMT: Thursday, August 15, 2019 6:14:35 PM
        let expiryDate = Date(timeIntervalSince1970: 1565892875)
        // GMT: Friday, January 21, 2022 9:03:45 AM
        let now = Date(timeIntervalSince1970: 1642755825)
        let coupon = Coupon.fake().copy(dateExpires: expiryDate)

        // Then
        XCTAssertEqual(coupon.expiryStatus(now: now), .expired)
    }
}
