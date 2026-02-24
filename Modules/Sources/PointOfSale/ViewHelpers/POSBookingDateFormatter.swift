import Foundation
import struct Yosemite.POSBooking

/// Formats booking dates for display in POS views.
///
/// The WooCommerce Bookings API encodes site-local wall-clock times as UTC
/// Unix timestamps. The raw epoch already represents the time at the store.
/// Because bookings are in-person services, we display site-local time
/// regardless of the device timezone by formatting in UTC (applying no offset).
///
/// For date selection, calendar display, and filtering by day, use
/// `siteTimezone` instead , those operations work with real calendar dates,
/// not API-encoded booking timestamps.
struct POSBookingDateFormatter {

    // Example: Time Range (e.g. "9:00 AM – 10:00 AM")
    private static let timeRangeFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    static func formattedTimeRange(for booking: POSBooking) -> String {
        timeRangeFormatter.string(from: booking.startDate, to: booking.endDate)
    }

    // Example: Date + Time (e.g. "Jan 15, 2025 at 9:00 AM")
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    static func formattedDateTime(for date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    // Example: Accessibility Time (e.g. "9:00 AM")
    private static let accessibilityTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    static func accessibilityFormattedTime(for date: Date) -> String {
        accessibilityTimeFormatter.string(from: date)
    }
}
