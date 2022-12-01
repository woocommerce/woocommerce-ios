import Foundation

final class AnalyticsHubDayRangeSelection: AnalyticsHubTimeRangeSelectionDelegate {
    var currentTimeRange: AnalyticsHubTimeRange?
    var previousTimeRange: AnalyticsHubTimeRange?
    var currentRangeDescription: String?
    var previousRangeDescription: String?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = currentCalendar.timeZone

        let currentDayStart = referenceDate.startOfDay(timezone: currentTimezone)
        let currentTimeRange = AnalyticsHubTimeRange(start: currentDayStart, end: referenceDate)
        self.currentTimeRange = currentTimeRange
        self.currentRangeDescription = DateFormatter.Stats.analyticsHubDayMonthYearFormatter.string(from: currentTimeRange.start)

        if let previousDay = currentCalendar.date(byAdding: .day, value: -1, to: referenceDate) {
            let previousDayStart = previousDay.startOfDay(timezone: currentTimezone)
            let previousTimeRange = AnalyticsHubTimeRange(start: previousDayStart, end: previousDay)
            self.previousTimeRange = previousTimeRange
            self.previousRangeDescription = DateFormatter.Stats.analyticsHubDayMonthYearFormatter.string(from: previousTimeRange.start)
        } else {
            self.previousTimeRange = nil
            self.previousRangeDescription = nil
        }
    }
}
