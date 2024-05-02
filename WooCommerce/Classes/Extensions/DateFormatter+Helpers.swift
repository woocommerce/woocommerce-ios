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

        /// Date formatter used for creating the date displayed on a chart axis for **day** granularity.
        ///
        public static let chartAxisDayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM d")
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
