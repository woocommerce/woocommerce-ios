import Foundation

/// Responsible for defining two ranges of data, one starting from the first day of the current quarter
/// until the current date and the previous one, starting from the first day of the previous quarter
/// until the same relative day of the previous quarter. E. g.
///
/// Today: 15 Feb 2022
/// Current range: Jan 1 until Feb 15, 2022
/// Previous range: Oct 1 until Nov 15, 2021
///
struct AnalyticsHubQuarterToDateRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.currentDateEnd = referenceDate
        self.currentDateStart = referenceDate.startOfQuarter(timezone: timezone, calendar: calendar)
        let previousDateEnd = calendar.date(byAdding: .month, value: -3, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfQuarter(timezone: timezone, calendar: calendar)
    }
}
