import Foundation
import struct Yosemite.POSBooking

/// Formats booking dates for display in POS views.
///
/// The WooCommerce Bookings API encodes site-local wall-clock times as UTC
/// Unix timestamps. The raw epoch already represents the time at the store.
/// Because bookings are in-person services, we display site-local time
/// regardless of the device timezone by formatting in UTC (applying no offset).
///
/// All booking-related date operations (display, calendar, filtering) use UTC
/// to match the API's encoding.
struct POSBookingDateFormatter {

    static let utcTimeZone = TimeZone(identifier: "UTC")!

    static let utcCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = utcTimeZone
        return calendar
    }()

    // Example: Time Range (e.g. "9:00 AM - 10:00 AM")
    private static let timeRangeFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = utcTimeZone
        return formatter
    }()

    static func formattedTimeRange(for booking: POSBooking) -> String {
        timeRangeFormatter.string(from: booking.startDate, to: booking.endDate)
    }

    // Example: Date + Time Range (e.g. "Mar 15 · 9:00 AM - 10:00 AM")
    static func formattedDateAndTimeRange(for booking: POSBooking) -> String {
        let date = shortDateFormatter.string(from: booking.startDate)
        let timeRange = timeRangeFormatter.string(from: booking.startDate, to: booking.endDate)
        return "\(date) · \(timeRange)"
    }

    // Example: Date + Time (e.g. "Jan 15, 2025 at 9:00 AM")
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = utcTimeZone
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
        formatter.timeZone = utcTimeZone
        return formatter
    }()

    static func accessibilityFormattedTime(for date: Date) -> String {
        accessibilityTimeFormatter.string(from: date)
    }

    // Example: Short Date (e.g. "Mon, Mar 15")
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMEEE")
        formatter.timeZone = utcTimeZone
        return formatter
    }()

    static func formattedShortDate(for date: Date) -> String {
        shortDateFormatter.string(from: date)
    }
}
