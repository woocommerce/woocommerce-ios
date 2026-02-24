import Foundation
import Testing
@testable import PointOfSale
import struct Yosemite.POSBooking
import struct Yosemite.POSOrder
import enum Networking.BookingStatus
import enum Networking.BookingAttendanceStatus

struct POSBookingDateFormatterTests {

    // 09:00 UTC on 2025-01-15 (Wednesday)
    private let referenceStart = Date(timeIntervalSince1970: 1_736_935_200)
    // 10:00 UTC on 2025-01-15
    private let referenceEnd = Date(timeIntervalSince1970: 1_736_938_800)

    // MARK: - formattedTimeRange

    @Test func test_formattedTimeRange_when_booking_has_known_UTC_times_then_output_contains_both_hours() {
        // Given
        let booking = makeBooking(startDate: referenceStart, endDate: referenceEnd)

        // When
        let result = POSBookingDateFormatter.formattedTimeRange(for: booking)

        // Then
        // DateIntervalFormatter may omit the AM/PM on the start time when both
        // times share the same period (e.g. "9:00 – 10:00 AM"), so we verify
        // the result against a same-configured DateIntervalFormatter in POSIX locale.
        let referenceIntervalFormatter = makePOSIXTimeRangeFormatter()
        let expected = referenceIntervalFormatter.string(from: referenceStart, to: referenceEnd)
        #expect(result == expected)
    }

    @Test func test_formattedTimeRange_when_same_input_given_twice_then_output_is_identical() {
        // Given
        let booking = makeBooking(startDate: referenceStart, endDate: referenceEnd)

        // When
        let first = POSBookingDateFormatter.formattedTimeRange(for: booking)
        let second = POSBookingDateFormatter.formattedTimeRange(for: booking)

        // Then
        #expect(first == second)
    }

    @Test func test_formattedTimeRange_when_end_is_after_start_then_output_is_non_empty() {
        // Given
        let booking = makeBooking(startDate: referenceStart, endDate: referenceEnd)

        // When
        let result = POSBookingDateFormatter.formattedTimeRange(for: booking)

        // Then
        #expect(!result.isEmpty)
    }

    // MARK: - formattedDateTime

    @Test func test_formattedDateTime_when_given_known_UTC_date_then_output_contains_date_and_time_components() {
        // Given
        let referenceFormatter = makePOSIXDateTimeFormatter()

        // When
        let result = POSBookingDateFormatter.formattedDateTime(for: referenceStart)

        // Then
        // The production formatter and the reference formatter share the same UTC
        // timezone, so their outputs must agree on the time portion regardless of
        // the device locale.
        let referenceTime = makePOSIXTimeFormatter().string(from: referenceStart)
        #expect(result.contains(referenceTime))
        // Date component: Jan 15, 2025 encoded as epoch seconds — verify the year
        // appears to confirm the date portion is included.
        #expect(result.contains("2025"))
        _ = referenceFormatter // suppress unused-variable warning
    }

    @Test func test_formattedDateTime_when_same_date_given_twice_then_output_is_identical() {
        // Given / When
        let first = POSBookingDateFormatter.formattedDateTime(for: referenceStart)
        let second = POSBookingDateFormatter.formattedDateTime(for: referenceStart)

        // Then
        #expect(first == second)
    }

    // MARK: - accessibilityFormattedTime

    @Test func test_accessibilityFormattedTime_when_given_known_UTC_date_then_output_matches_UTC_time_only() {
        // Given
        let referenceFormatter = makePOSIXTimeFormatter()
        let expected = referenceFormatter.string(from: referenceStart)

        // When
        let result = POSBookingDateFormatter.accessibilityFormattedTime(for: referenceStart)

        // Then
        #expect(result == expected)
    }

    @Test func test_accessibilityFormattedTime_when_same_date_given_twice_then_output_is_identical() {
        // Given / When
        let first = POSBookingDateFormatter.accessibilityFormattedTime(for: referenceStart)
        let second = POSBookingDateFormatter.accessibilityFormattedTime(for: referenceStart)

        // Then
        #expect(first == second)
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

    /// A time range formatter pinned to en_US_POSIX locale and UTC, mirroring
    /// the production `timeRangeFormatter` configuration.
    func makePOSIXTimeRangeFormatter() -> DateIntervalFormatter {
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }

    /// A time-only formatter pinned to en_US_POSIX locale and UTC, mirroring
    /// the production `accessibilityTimeFormatter` configuration.
    func makePOSIXTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }

    /// A date+time formatter pinned to en_US_POSIX locale and UTC, mirroring
    /// the production `dateTimeFormatter` configuration.
    func makePOSIXDateTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
}
