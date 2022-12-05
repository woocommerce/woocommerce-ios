import Foundation

struct AnalyticsHubLastYearRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: referenceDate)
        self.currentDateEnd = oneYearAgo?.endOfYear(timezone: timezone)
        self.currentDateStart = oneYearAgo?.startOfYear(timezone: timezone)

        let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: referenceDate)
        self.previousDateEnd = twoYearsAgo?.endOfYear(timezone: timezone)
        self.previousDateStart = twoYearsAgo?.startOfYear(timezone: timezone)
    }
}
