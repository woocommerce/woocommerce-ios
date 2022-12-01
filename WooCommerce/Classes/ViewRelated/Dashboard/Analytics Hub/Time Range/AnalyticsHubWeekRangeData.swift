import Foundation

struct AnalyticsHubWeekRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let previousDateStart: Date?
    let previousDateEnd: Date?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = currentCalendar.timeZone

        self.currentDateEnd = referenceDate
        self.currentDateStart = referenceDate.startOfWeek(timezone: currentTimezone, calendar: currentCalendar)

        let previousDateEnd = currentCalendar.date(byAdding: .day, value: -7, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfWeek(timezone: currentTimezone, calendar: currentCalendar)
    }
}
