import Foundation

struct AnalyticsHubLastWeekRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: referenceDate)
        self.currentDateEnd = oneWeekAgo?.endOfWeek(timezone: timezone, calendar: calendar)
        self.currentDateStart = oneWeekAgo?.startOfWeek(timezone: timezone, calendar: calendar)

        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: referenceDate)
        self.previousDateEnd = twoWeeksAgo?.endOfWeek(timezone: timezone, calendar: calendar)
        self.previousDateStart = twoWeeksAgo?.startOfWeek(timezone: timezone, calendar: calendar)
    }
}
