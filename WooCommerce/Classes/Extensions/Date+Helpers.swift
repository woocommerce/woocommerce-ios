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

    /// Chart Formatters
    ///
    struct Charts {

        /// Date formatter used for creating the date displayed on a chart axis for **day** granularity.
        ///
        public static let chartsDayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.dateFormat = "MMM d"
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart axis for **week** granularity.
        ///
        public static let chartsWeekFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.dateFormat = "MMM d"
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart axis for **month** granularity.
        ///
        public static let chartsMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.dateFormat = "MMM"
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart axis for **year** granularity.
        ///
        public static let chartsYearFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.dateFormat = "yyyy"
            return formatter
        }()
    }

}
