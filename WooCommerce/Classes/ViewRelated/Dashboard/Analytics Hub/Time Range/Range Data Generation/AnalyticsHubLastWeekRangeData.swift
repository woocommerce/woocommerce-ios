import Foundation

/// Responsible for defining two ranges of data, one starting from the first day of the last week
/// until the final day of that week, and the previous one as two weeks ago, also starting
/// from the first day until the final day of that week. E. g.
///
/// Today: 29 Jul 2022
/// Current range: Jul 18 until Jul 24, 2022
/// Previous range: Jul 11 until Jul 17, 2022
///
struct AnalyticsHubLastWeekRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let formattedCurrentRange: String?

    let previousDateStart: Date?
    let previousDateEnd: Date?
    let formattedPreviousRange: String?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: referenceDate)
        self.currentDateEnd = oneWeekAgo?.endOfWeek(timezone: timezone, calendar: calendar)
        self.currentDateStart = oneWeekAgo?.startOfWeek(timezone: timezone, calendar: calendar)
        self.formattedCurrentRange = currentDateStart?.formatAsRange(with: currentDateEnd, timezone: timezone, calendar: calendar)

        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: referenceDate)
        self.previousDateEnd = twoWeeksAgo?.endOfWeek(timezone: timezone, calendar: calendar)
        self.previousDateStart = twoWeeksAgo?.startOfWeek(timezone: timezone, calendar: calendar)
        self.formattedPreviousRange = previousDateStart?.formatAsRange(with: previousDateEnd, timezone: timezone, calendar: calendar)
    }
}
