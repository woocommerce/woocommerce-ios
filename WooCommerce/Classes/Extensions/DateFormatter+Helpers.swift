import Foundation

/// DateFormatter Extensions
///
extension DateFormatter {

    /// Chart Formatters
    ///
    struct Charts {

        // MARK: - Chark axis formatters

        /// Date formatter used for creating the date displayed on a chart axis for **day** granularity.
        ///
        public static let chartAxisDayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM d")
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

        /// Date formatter used for creating the date displayed on a chart axis for **year** granularity.
        ///
        public static let chartAxisYearFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("yyyy")
            return formatter
        }()


        // MARK: - Chark marker formatters

        /// Date formatter used for creating the date displayed on a chart marker for **day** granularity.
        ///
        public static let chartMarkerDayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM d")
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart marker for **week** granularity.
        ///
        public static let chartMarkerWeekFormatter: DateFormatter = {
            let formatter = DateFormatter()
            // Note: Passing "w Y" into `setLocalizedDateFormatFromTemplate()` will result in an empty string, however
            // simply passing in "w" works. So that is what we have to unfortunately do here.
            formatter.setLocalizedDateFormatFromTemplate("w")
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart marker for **month** granularity.
        ///
        public static let chartMarkerMonthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
            return formatter
        }()

        /// Date formatter used for creating the date displayed on a chart marker for **year** granularity.
        ///
        public static let chartMarkerYearFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("yyyy")
            return formatter
        }()
    }
}
