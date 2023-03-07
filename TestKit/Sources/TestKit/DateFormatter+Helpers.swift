import Foundation

/// DateFormatter Extensions
///
extension DateFormatter {

    /// Date And Time Formatter. Converts String to Date type
    ///
    static public func dateFromString(with dateString: String,
                                      locale: Locale? = .init(identifier: "en_US_POSIX"),
                                      timeZone: TimeZone? = .init(identifier: "GMT"),
                                      dateFormat: String? = "yyyy'-'MM'-'dd'T'HH:mm:ss") -> Date {

        let formatter = DateFormatter()

        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = dateFormat

        guard let date = formatter.date(from: dateString) else {
            return Date()
        }

        return date
    }
}
