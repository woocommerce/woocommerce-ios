import Foundation

struct AnalyticsHubWeekRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.currentDateEnd = referenceDate
        self.currentDateStart = referenceDate.startOfWeek(timezone: timezone, calendar: calendar)
        let previousDateEnd = calendar.date(byAdding: .day, value: -7, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfWeek(timezone: timezone, calendar: calendar)
    }
}
