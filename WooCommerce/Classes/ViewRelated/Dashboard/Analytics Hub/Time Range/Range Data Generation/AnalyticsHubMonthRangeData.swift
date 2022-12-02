import Foundation

struct AnalyticsHubMonthRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.currentDateEnd = referenceDate
        self.currentDateStart = referenceDate.startOfMonth(timezone: timezone)
        let previousDateEnd = calendar.date(byAdding: .month, value: -1, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfMonth(timezone: timezone)
    }
}
