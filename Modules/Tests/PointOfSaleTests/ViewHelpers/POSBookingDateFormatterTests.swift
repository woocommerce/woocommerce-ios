import Foundation
import Testing
@testable import PointOfSale
import struct Yosemite.POSBooking
import struct Yosemite.POSOrder
import enum Networking.BookingStatus
import enum Networking.BookingAttendanceStatus

struct POSBookingDateFormatterTests {

    // 10:00 UTC on 2025-01-15 (Wednesday)
    private let referenceStart = Date(timeIntervalSince1970: 1_736_935_200)
    // 11:00 UTC on 2025-01-15
    private let referenceEnd = Date(timeIntervalSince1970: 1_736_938_800)

    // MARK: - formattedTimeRange

    @Test func test_formattedTimeRange_formats_using_UTC_hours() {
        // Given
        let booking = makeBooking(startDate: referenceStart, endDate: referenceEnd)

        // When
        let result = POSBookingDateFormatter.formattedTimeRange(for: booking)

        // Then - contains UTC hours 10 and 11, no date components
        #expect(result.contains("10"))
        #expect(result.contains("11"))
        #expect(!result.contains("2025"))
        #expect(!result.contains("15"))
    }

    // MARK: - formattedDateTime

    @Test func test_formattedDateTime_formats_using_UTC_date_and_time() {
        // When
        let result = POSBookingDateFormatter.formattedDateTime(for: referenceStart)

        // Then - contains both UTC date and time components
        #expect(result.contains("10"))
        #expect(result.contains("15"))
        #expect(result.contains("2025"))
    }

    // MARK: - accessibilityFormattedTime

    @Test func test_accessibilityFormattedTime_formats_using_UTC_hour() {
        // When
        let result = POSBookingDateFormatter.accessibilityFormattedTime(for: referenceStart)

        // Then - contains UTC hour only, no date components
        #expect(result.contains("10"))
        #expect(!result.contains("2025"))
        #expect(!result.contains("15"))
    }

    // MARK: - formattedShortDate

    @Test func test_formattedShortDate_formats_using_UTC_date() {
        // When
        let result = POSBookingDateFormatter.formattedShortDate(for: referenceStart)

        // Then - contains day in UTC, no year or time
        #expect(result.contains("15"))
        #expect(!result.contains("2025"))
        #expect(!result.contains("10:"))
    }
}

// MARK: - Helpers

private extension POSBookingDateFormatterTests {

    func makeBooking(startDate: Date, endDate: Date) -> POSBooking {
        POSBooking(
            id: 1,
            customerName: "Jane Doe",
            serviceName: "Test Service",
            startDate: startDate,
            endDate: endDate,
            formattedAmount: "$50.00",
            status: .confirmed,
            attendanceStatus: .unattended,
            orderID: 10,
            resourceName: nil,
            order: makeOrder()
        )
    }

    func makeOrder() -> POSOrder {
        POSOrder(
            id: 10,
            number: "10",
            dateCreated: Date(),
            status: .completed,
            formattedTotal: "$50.00",
            formattedSubtotal: "$50.00",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash",
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$50.00",
            datePaid: nil
        )
    }
}
