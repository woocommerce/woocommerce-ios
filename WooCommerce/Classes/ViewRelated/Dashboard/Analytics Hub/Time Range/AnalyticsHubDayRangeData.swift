import Foundation

struct AnalyticsHubDayRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = currentCalendar.timeZone

        self.currentDateEnd = referenceDate
        self.currentDateStart = referenceDate.startOfDay(timezone: currentTimezone)

        let previousDateEnd = currentCalendar.date(byAdding: .day, value: -1, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfDay(timezone: currentTimezone)
    }
}
