import Foundation

final class AnalyticsHubDayRangeSelection: AnalyticsHubTimeRangeSelection {
    var currentTimeRange: AnalyticsHubTimeRange?
    var previousTimeRange: AnalyticsHubTimeRange?
    var currentRangeDescription: String?
    var previousRangeDescription: String?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = TimeZone.autoupdatingCurrent

        let currentDayStart = referenceDate.startOfDay(timezone: currentTimezone)
        let currentTimeRange = AnalyticsHubTimeRange(start: currentDayStart, end: referenceDate)
        self.currentTimeRange = currentTimeRange
        self.currentRangeDescription = currentTimeRange.generateDescription(referenceCalendar: currentCalendar)

        if let previousDay = currentCalendar.date(byAdding: .day, value: -1, to: referenceDate) {
            let previousDayStart = previousDay.startOfDay(timezone: currentTimezone)
            let previousTimeRange = AnalyticsHubTimeRange(start: previousDayStart, end: previousDay)
            self.previousTimeRange = previousTimeRange
            self.previousRangeDescription = previousTimeRange.generateDescription(referenceCalendar: currentCalendar)
        } else {
            self.previousTimeRange = nil
            self.previousRangeDescription = nil
        }
    }
}
