import Foundation


/// DateFormatter Extensions
///
extension DateFormatter {

    /// Default Formatters
    ///
    struct Defaults {

        /// Date And Time Formatter
        ///
        static let dateTimeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH:mm:ss"
            return formatter
        }()
    }
}
