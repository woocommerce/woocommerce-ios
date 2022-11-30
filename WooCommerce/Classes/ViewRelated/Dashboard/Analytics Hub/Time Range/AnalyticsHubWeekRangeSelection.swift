import Foundation

final class AnalyticsHubWeekRangeSelection: AnalyticsHubTimeRangeSelection {
    var currentTimeRange: AnalyticsHubTimeRange?

    var previousTimeRange: AnalyticsHubTimeRange?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = TimeZone.autoupdatingCurrent

        if let currentWeekStart = referenceDate.startOfWeek(timezone: currentTimezone, calendar: currentCalendar) {
            self.currentTimeRange = AnalyticsHubTimeRange(start: currentWeekStart, end: referenceDate)
        } else {
            self.currentTimeRange = nil
        }

        if let oneWeekAgo = currentCalendar.date(byAdding: .day, value: -7, to: referenceDate),
           let previousWeekStart = oneWeekAgo.startOfWeek(timezone: currentTimezone, calendar: currentCalendar) {
            self.previousTimeRange = AnalyticsHubTimeRange(start: previousWeekStart, end: oneWeekAgo)
        } else {
            self.previousTimeRange = nil
        }
    }
}
