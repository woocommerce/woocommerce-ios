import Foundation

struct AnalyticsHubLastMonthRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: referenceDate)
        self.currentDateEnd = oneMonthAgo?.endOfMonth(timezone: timezone)
        self.currentDateStart = oneMonthAgo?.startOfMonth(timezone: timezone)

        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: referenceDate)
        self.previousDateEnd = twoMonthsAgo?.endOfMonth(timezone: timezone)
        self.previousDateStart = twoMonthsAgo?.startOfMonth(timezone: timezone)
    }
}
