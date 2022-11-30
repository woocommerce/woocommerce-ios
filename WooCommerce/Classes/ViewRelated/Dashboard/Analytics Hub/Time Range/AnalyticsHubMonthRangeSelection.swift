import Foundation

final class AnalyticsHubMonthRangeSelection: AnalyticsHubTimeRangeSelection {
    var currentTimeRange: AnalyticsHubTimeRange?
    var previousTimeRange: AnalyticsHubTimeRange?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = TimeZone.autoupdatingCurrent

        if let currentMonthStart = referenceDate.startOfMonth(timezone: currentTimezone) {
            self.currentTimeRange = AnalyticsHubTimeRange(start: currentMonthStart, end: referenceDate)
        } else {
            self.currentTimeRange = nil
        }

        if let oneMonthAgo = currentCalendar.date(byAdding: .month, value: -1, to: referenceDate),
           let previousMonthStart = oneMonthAgo.startOfMonth(timezone: currentTimezone) {
            self.previousTimeRange = AnalyticsHubTimeRange(start: previousMonthStart, end: oneMonthAgo)
        } else {
            self.previousTimeRange = nil
        }
    }
}
