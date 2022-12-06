import Foundation

struct AnalyticsHubQuarterToDateRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.currentDateEnd = referenceDate
        self.currentDateStart = referenceDate.startOfQuarter(timezone: timezone, calendar: calendar)
        let previousDateEnd = calendar.date(byAdding: .quarter, value: -1, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfQuarter(timezone: timezone, calendar: calendar)
    }
}
