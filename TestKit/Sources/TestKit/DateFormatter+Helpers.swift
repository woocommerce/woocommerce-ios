import Foundation

/// DateFormatter Extensions
///
extension DateFormatter {

    /// Date And Time Formatter. Converts String to Date type
    ///
    static public func dateFromString(with dateString: String) -> Date {

        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH:mm:ss"

        guard let date = formatter.date(from: dateString) else {
            return Date()
        }

        return date
    }
}
