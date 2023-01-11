import Foundation

/// DateFormatter Extensions
///
extension DateFormatter {

    /// Chart Formatters
    ///
    struct Charts {

        // MARK: - Chark axis formatters

        /// Date formatter used for creating the date for a selected date displayed on the time range bar for **hour** granularity.
        ///
        public static let chartSelectedDateHourFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d, h:mm a")
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart axis for **hour** granularity.
        ///
        public static let chartAxisHourFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("ha")
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart axis for **day** granularity.
        ///
        public static let chartAxisDayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM d")
            return formatter
        }()

        /// Date formatter used for creating the day of month displayed on a chart axis for **day** granularity.
        ///
        public static let chartAxisDayOfMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("d")
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart axis for **week** granularity.
        ///
        public static let chartAxisWeekFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM d")
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart axis for **month** granularity.
        ///
        public static let chartAxisMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM")
            return formatter
        }()

        /// Date formatter used for displaying the full month on a chart axis.
        ///
        public static let chartAxisFullMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart axis for **year** granularity.
        ///
        public static let chartAxisYearFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("yyyy")
            return formatter
        }()


        // MARK: - Chark marker formatters

        /// Date formatter used for creating a **localized** date string displayed on a chart marker for **day** granularity.
        ///
        /// Example Output: "Dec 30" or "12月30日"
        ///
        public static var chartMarkerDayFormatter: DateFormatter {
            monthAndDayFormatter
        }

        /// Date formatter used for creating a **localized** date string displayed on a chart marker for **week** granularity.
        ///
        /// Example Output: "1" or "23" (week number)
        ///
        public static let chartMarkerWeekFormatter: DateFormatter = {
            let formatter = DateFormatter()
            // Note: Passing "w Y" into `setLocalizedDateFormatFromTemplate()` will result in an empty string, however
            // simply passing in "w" works. So that is what we have to unfortunately do here.
            formatter.setLocalizedDateFormatFromTemplate("w")
            return formatter
        }()

        /// Date formatter used for creating a **localized** date string displayed on a chart marker for **month** granularity.
        ///
        /// Example Output: "Jan 2018" or "2018年1月"
        ///
        public static let chartMarkerMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
            return formatter
        }()

        /// Date formatter used for creating a **localized** date string displayed on a chart marker for **year** granularity.
        ///
        /// Example Output: "2018" or "2017"
        ///
        public static var chartMarkerYearFormatter: DateFormatter {
            yearFormatter
        }
    }

    struct Stats {
        /// Date formatter used for creating the properly-formatted date range info. Typically
        /// used when setting the end date on `AnalyticsHubTimeRangeGenerator`.
        ///
        public static func createAnalyticsHubDayMonthYearFormatter(timezone: TimeZone) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "MMM d, yyyy"
            return formatter
        }

        /// Date formatter used for creating the properly-formatted date range info. Typically
        /// used when setting the end date of a same-month range on `AnalyticsHubTimeRangeGenerator`.
        ///
        public static func createAnalyticsHubDayYearFormatter(timezone: TimeZone) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "d, yyyy"
            return formatter
        }

        /// Date formatter used for creating the properly-formatted date range info. Typically
        /// used when setting the start date on `AnalyticsHubTimeRangeGenerator`.
        ///
        public static func createAnalyticsHubDayMonthFormatter(timezone: TimeZone) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.timeZone = timezone
            formatter.dateFormat = "MMM d"
            return formatter
        }

        /// Date formatter used for creating a **localized** date range string based on two dates. E.g.
        ///
        /// start: 2021-01-01
        /// end: 2022-12-31
        /// returns: Jan 1, 2021 - Dec 31, 2022
        ///
        /// start: 2021-01-01
        /// end: 2021-01-31
        /// returns: Jan 1 - 31, 2022
        ///
        /// start: 2021-01-01
        /// end: 2022-01-01
        /// returns: Jan 1, 2021 - Jan 1, 2022
        ///
        public static func formatAsRange(using start: Date?, and end: Date?, timezone: TimeZone, calendar: Calendar) -> String? {
            guard let start = start,
                  let end = end else {
                return nil
            }

            let formattedStart: String
            if start.isSameYear(as: end, using: calendar) {
                formattedStart = createAnalyticsHubDayMonthFormatter(timezone: timezone).string(from: start)
            } else {
                formattedStart = createAnalyticsHubDayMonthYearFormatter(timezone: timezone).string(from: start)
            }

            let formattedEnd: String
            if start.isSameMonth(as: end, using: calendar) {
                formattedEnd = createAnalyticsHubDayYearFormatter(timezone: timezone).string(from: end)
            } else {
                formattedEnd = createAnalyticsHubDayMonthYearFormatter(timezone: timezone).string(from: end)
            }

            return "\(formattedStart) - \(formattedEnd)"
        }
        
        public static func unwrapString(from date: Date?) -> String? {
            if let date = date {
                return DateFormatter().string(from: date)
            }
            return nil
        }
    }

    /// Date formatter used for creating a medium-length **localized** date string to be displayed anywhere.
    ///
    /// Example output in English: "Jan 28, 2018"
    ///
    public static let mediumLengthLocalizedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d yyyy")

        return formatter
    }()

    /// Date formatter used for creating a **localized** string containing the month and day.
    ///
    /// Example Output: "Dec 30" or "12月30日"
    ///
    static let monthAndDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    /// Date formatter used for creating a **localized** string of the year only.
    ///
    /// Example Output: "2018" or "2017"
    ///
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        return formatter
    }()

    /// Localized date formatter that generates the time only. Example, “11:23 AM”.
    ///
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("hh:mm a")
        return formatter
    }()

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
