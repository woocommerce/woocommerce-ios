import Foundation

final class AnalyticsHubDayRangeSelection: AnalyticsHubTimeRangeSelection {
    var currentTimeRange: AnalyticsHubTimeRange?

    var previousTimeRange: AnalyticsHubTimeRange?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = TimeZone.autoupdatingCurrent

        let currentDayStart = referenceDate.startOfDay(timezone: currentTimezone)
        self.currentTimeRange = AnalyticsHubTimeRange(start: currentDayStart, end: referenceDate)

        if let previousDay = currentCalendar.date(byAdding: .day, value: -1, to: referenceDate) {
            let previousDayStart = previousDay.startOfDay(timezone: currentTimezone)
            self.previousTimeRange = AnalyticsHubTimeRange(start: previousDayStart, end: previousDay)
        } else {
            self.previousTimeRange = nil
        }
    }
}
