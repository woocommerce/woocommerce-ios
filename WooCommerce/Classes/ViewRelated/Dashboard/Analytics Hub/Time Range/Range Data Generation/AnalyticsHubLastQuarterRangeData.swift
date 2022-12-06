import Foundation

struct AnalyticsHubLastQuarterRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let oneQuarterAgo = calendar.date(byAdding: .month, value: -3, to: referenceDate)
        self.currentDateEnd = oneQuarterAgo?.endOfQuarter(timezone: timezone, calendar: calendar)
        self.currentDateStart = oneQuarterAgo?.startOfQuarter(timezone: timezone, calendar: calendar)

        let twoQuartersAgo = calendar.date(byAdding: .month, value: -6, to: referenceDate)
        self.previousDateEnd = twoQuartersAgo?.endOfQuarter(timezone: timezone, calendar: calendar)
        self.previousDateStart = twoQuartersAgo?.startOfQuarter(timezone: timezone, calendar: calendar)
    }
}
