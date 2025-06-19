import Foundation


/// DateFormatter Extensions
///
public extension DateFormatter {

    /// Default Formatters
    ///
    struct Defaults {

        /// Date And Time Formatter
        ///
        public static let dateTimeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH:mm:ss"
            return formatter
        }()

        /// Year-Month-Day date formatter with en_US_POSIX locale
        ///
        /// Example output: `2019-02-01` or `2019-11-28`
        ///
        public static let yearMonthDayDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy'-'MM'-'dd"
            return formatter
        }()

        /// ISO8601 DateFormatter
        ///
        public static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "GMT")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            return formatter
        }()

        /// ISO8601 DateFormatter without time zone
        ///
        public static let iso8601WithoutTimeZone: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter
        }()
    }


    /// Stats Formatters
    ///
    struct Stats {

        /// Date formatter used for creating the properly-formatted date string for **day** granularity. Typically
        /// used when setting the `latestDateToInclude` on `OrderStatsRemote`.
        ///
        public static let statsDayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy'-'MM'-'dd"
            return formatter
        }()

        /// Date formatter used for creating the properly-formatted date string for **week** granularity. Typically
        /// used when setting the `latestDateToInclude` on `OrderStatsRemote`.
        ///
        public static let statsWeekFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy'-W'ww"
            return formatter
        }()

        /// Date formatter used for creating the properly-formatted date string for **month** granularity. Typically
        /// used when setting the `latestDateToInclude` on `OrderStatsRemote`.
        ///
        public static let statsMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy'-'MM"
            return formatter
        }()

        /// Date formatter used for creating the properly-formatted date string for **year** granularity. Typically
        /// used when setting the `latestDateToInclude` on `OrderStatsRemote`.
        ///
        public static let statsYearFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy"
            return formatter
        }()

        /// Date And Time Formatter used for creating the date strings in `OrderStatsV4Interval`'s `dateStart`/`dateEnd`.
        ///
        public static let dateTimeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter
        }()

        /// Date formatter used for creating the properly-formatted date range info. Typically
        /// used when setting the end date on `AnalyticsHubTimeRangeGenerator`.
        ///
        public static func createDayMonthYearFormatter(timezone: TimeZone) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "MMM d, yyyy"
            return formatter
        }

        /// Date formatter used for creating the properly-formatted date range info. Typically
        /// used when setting the end date of a same-month range on `AnalyticsHubTimeRangeGenerator`.
        ///
        public static func createDayYearFormatter(timezone: TimeZone) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "d, yyyy"
            return formatter
        }

        /// Date formatter used for creating the properly-formatted date range info. Typically
        /// used when setting the start date on `AnalyticsHubTimeRangeGenerator`.
        ///
        public static func createDayMonthFormatter(timezone: TimeZone) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "MMM d"
            return formatter
        }
    }
}
