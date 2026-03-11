import Foundation

extension DateFormatter {
    /// Creates a common DateFormatter for date and time display in POS views.
    ///
    static func posDateAndTimeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d yyyy hh:mm a")
        formatter.timeZone = timeZone
        return formatter
    }
}
