import Foundation

/// DateFormatter Extensions
///
extension DateFormatter {
    /// Date formatter used for creating a **localized** date and time string.
    ///
    /// Example output in English: "Jan 28, 2018, 11:23 AM"
    ///
    public static let dateAndTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d yyyy hh:mm a")

        return formatter
    }()
}
