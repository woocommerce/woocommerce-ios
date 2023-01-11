import Foundation

/// Responsible for defining two ranges of data, one starting from the the first second of yesterday
/// until the last minute of  the same day and the previous one, starting from the first second of
/// the day before yesterday until the end of that day. E. g.
///
/// Today: 29 Jul 2022
/// Current range: Jul 28 until Jul 28, 2022
/// Previous range: Jul 27 until Jul 27, 2022
///
struct AnalyticsHubYesterdayRangeData: AnalyticsHubTimeRangeData {
    let referenceDate: Date?

    let currentDateStart: Date?
    let currentDateEnd: Date?
    let formattedCurrentRange: String?

    let previousDateStart: Date?
    let previousDateEnd: Date?
    let formattedPreviousRange: String?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let formatter = DateFormatter.Stats.createAnalyticsHubDayMonthYearFormatter(timezone: timezone)
        self.referenceDate = referenceDate

        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate)
        self.currentDateEnd = yesterday?.endOfDay(timezone: timezone)
        self.currentDateStart = yesterday?.startOfDay(timezone: timezone)
        if let currentDateEnd = currentDateEnd {
            self.formattedCurrentRange = formatter.string(from: currentDateEnd)
        } else {
            self.formattedCurrentRange = nil
        }

        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: referenceDate)
        self.previousDateEnd = dayBeforeYesterday?.endOfDay(timezone: timezone)
        self.previousDateStart = dayBeforeYesterday?.startOfDay(timezone: timezone)
        if let previousDateEnd = previousDateEnd {
            self.formattedPreviousRange = formatter.string(from: previousDateEnd)
        } else {
            self.formattedPreviousRange = nil
        }
    }
}
