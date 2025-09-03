import Foundation
import Testing
@testable import Yosemite

struct POSCouponTests {
    @Test func test_isExpired_when_no_expiration_date_then_returns_false() {
        // Given
        let coupon = POSCoupon(id: UUID(), code: "valid-forever")

        // Then
        #expect(coupon.isExpired == false)
    }

    @Test func test_isExpired_when_future_date_then_returns_false() {
        // Given
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let coupon = POSCoupon(id: UUID(), code: "will-expire-in-the-future", dateExpires: tomorrow)

        // Then
        #expect(coupon.isExpired == false)
    }

    @Test func test_isExpired_when_past_date_then_returns_true() {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let coupon = POSCoupon(id: UUID(), code: "expired-yesterday", dateExpires: yesterday)

        // Then
        #expect(coupon.isExpired == true)
    }

    @Test func test_isExpired_when_current_date_then_returns_true() {
        // Given
        let now = fixedDate(daysFromReference: 0)
        let coupon = POSCoupon(id: UUID(), code: "expired-now", dateExpires: now)

        // Then
        #expect(coupon.isExpired == true, "A coupon expiring at the current time should be considered expired")
    }
}

private extension POSCouponTests {
    /// Returns a fixed date with optional day offset
    /// - Parameter daysFromReference: Number of days to add/subtract from the reference date (0 = reference date)
    /// - Returns: A fixed date
    func fixedDate(daysFromReference: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")

        guard let baseDate = Calendar(identifier: .gregorian).date(from: components) else {
            // Fallback to the same date (2024-06-15 12:00:00 UTC) if calendar creation fails
            return Date(timeIntervalSince1970: 1718452800)
        }
        guard daysFromReference != 0 else { return baseDate }

        return Calendar.current.date(byAdding: .day, value: daysFromReference, to: baseDate) ?? baseDate
    }
}
