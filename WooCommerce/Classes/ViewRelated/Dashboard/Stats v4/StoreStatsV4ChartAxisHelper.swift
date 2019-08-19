import Yosemite

/// A helper for the labels for store stats v4 charts UI.
class StoreStatsV4ChartAxisHelper {
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
    /// - Parameter intervals: interval data of the chart
    /// - Returns: an array of the same length as input, that contains the text to be shown on chart x axis
    func generateLabelText(for intervals: [OrderStatsV4Interval], timeRange: StatsTimeRangeV4, siteTimezone: TimeZone) -> [String] {
        let chartDateFormatter = timeRange.chartDateFormatter(siteTimezone: siteTimezone)
        guard timeRange.intervalGranularity == .daily else {
            return intervals.map({ chartDateFormatter.string(from: $0.dateStart()) })
        }

        var intervalLabelText = [String]()

        let calendar = Calendar.current
        var latestMonth: Int? = nil
        let dayOfMonthDateFormatter = DateFormatter.Charts.chartAxisDayOfMonthFormatter
        for interval in intervals {
            let date = interval.dateStart()
            let month = calendar.component(.month, from: date)
            if month != latestMonth {
                let labelText = chartDateFormatter.string(from: date)
                intervalLabelText.append(labelText)
                latestMonth = month
            } else {
                // If the month is the same as the last, the label text just shows the day of month without month.
                let labelText = dayOfMonthDateFormatter.string(from: date)
                intervalLabelText.append(labelText)
            }
        }
        return intervalLabelText
    }
}
