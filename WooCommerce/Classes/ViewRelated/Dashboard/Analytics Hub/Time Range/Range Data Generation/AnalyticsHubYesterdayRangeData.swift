import Foundation

struct AnalyticsHubYesterdayRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate)
        self.currentDateEnd = yesterday?.endOfDay(timezone: timezone)
        self.currentDateStart = yesterday?.startOfDay(timezone: timezone)

        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: referenceDate)
        self.previousDateEnd = dayBeforeYesterday?.endOfDay(timezone: timezone)
        self.previousDateStart = dayBeforeYesterday?.startOfDay(timezone: timezone)
    }
}
