import Foundation

/// Responsible for defining two ranges of data, one starting from the first day of the current month
/// until the current date and the previous one, starting from the first day of the previous month
/// until the same day of the previous month. E. g.
///
/// Today: 31 Jul 2022
/// Current range: Jul 1 until Jul 31, 2022
/// Previous range: Jun 1 until Jun 30, 2022
///
struct AnalyticsHubMonthToDateRangeData: AnalyticsHubTimeRangeData {
    let referenceDate: Date?

    let currentDateStart: Date?
    let currentDateEnd: Date?

    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.referenceDate = referenceDate
        self.currentDateEnd = referenceDate.endOfMonth(timezone: timezone)
        self.currentDateStart = referenceDate.startOfMonth(timezone: timezone)
        let previousDateEnd = calendar.date(byAdding: .month, value: -1, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfMonth(timezone: timezone)
    }
}
