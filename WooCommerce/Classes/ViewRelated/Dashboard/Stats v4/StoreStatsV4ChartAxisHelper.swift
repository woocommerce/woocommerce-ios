import Yosemite

/// A helper for the labels for store stats v4 charts UI.
final class StoreStatsV4ChartAxisHelper {
    func labelCount(timeRange: StatsTimeRangeV4) -> Int {
        let labelCount: Int
        switch timeRange {
        case .thisYear:
            labelCount = 4
        case .today:
            labelCount = 5
        case .thisMonth:
            labelCount = 6
        case .thisWeek:
            labelCount = 7
        }
        return labelCount
    }

    /// Generates an array of label text that is shown on the chart x axis
    ///
    /// - Parameter dates: an array of date for each stats interval
    /// - Returns: an array of the same length as input, that contains the text to be shown on chart x axis
    func generateLabelText(for dates: [Date], timeRange: StatsTimeRangeV4, siteTimezone: TimeZone) -> [String] {
        let chartDateFormatter = timeRange.chartDateFormatter(siteTimezone: siteTimezone)
        guard timeRange.intervalGranularity == .daily else {
            return dates.map({ chartDateFormatter.string(from: $0) })
        }

        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        var latestMonth: Int? = nil
        let dayOfMonthDateFormatter = DateFormatter.Charts.chartAxisDayOfMonthFormatter
        dayOfMonthDateFormatter.timeZone = siteTimezone

        let dateLabelText = dates.reduce([]) { (dateLabelText, date) -> [String] in
            let month = calendar.component(.month, from: date)
            if month != latestMonth {
                let labelText = chartDateFormatter.string(from: date)
                latestMonth = month
                return dateLabelText + [labelText]
            } else {
                // If the month is the same as the last, the label text just shows the day of month without month.
                let labelText = dayOfMonthDateFormatter.string(from: date)
                return dateLabelText + [labelText]
            }
        }
        return dateLabelText
    }
}
