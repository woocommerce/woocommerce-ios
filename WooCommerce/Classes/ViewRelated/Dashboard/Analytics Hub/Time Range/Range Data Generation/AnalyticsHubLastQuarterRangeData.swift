import Foundation

struct AnalyticsHubLastQuarterRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.currentDateEnd = referenceDate.endOfQuarter(timezone: timezone, calendar: calendar)
        self.currentDateStart = referenceDate.startOfQuarter(timezone: timezone, calendar: calendar)
        let previousDateEnd = calendar.date(byAdding: .month, value: -3, to: referenceDate)
        self.previousDateEnd = previousDateEnd?.endOfQuarter(timezone: timezone, calendar: calendar)
        self.previousDateStart = previousDateEnd?.startOfQuarter(timezone: timezone, calendar: calendar)
    }
}
