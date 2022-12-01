import Foundation

final class AnalyticsHubWeekRangeSelection: AnalyticsHubTimeRangeSelectionDelegate {
    var currentTimeRange: AnalyticsHubTimeRange?
    var previousTimeRange: AnalyticsHubTimeRange?
    var currentRangeDescription: String?
    var previousRangeDescription: String?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = currentCalendar.timeZone

        if let currentWeekStart = referenceDate.startOfWeek(timezone: currentTimezone, calendar: currentCalendar) {
            let currentTimeRange = AnalyticsHubTimeRange(start: currentWeekStart, end: referenceDate)
            self.currentTimeRange = currentTimeRange
            self.currentRangeDescription = currentTimeRange.generateDescription(referenceCalendar: currentCalendar)
        } else {
            self.currentTimeRange = nil
            self.currentRangeDescription = nil
        }

        if let oneWeekAgo = currentCalendar.date(byAdding: .day, value: -7, to: referenceDate),
           let previousWeekStart = oneWeekAgo.startOfWeek(timezone: currentTimezone, calendar: currentCalendar) {
            let previousTimeRange = AnalyticsHubTimeRange(start: previousWeekStart, end: oneWeekAgo)
            self.previousTimeRange = previousTimeRange
            self.previousRangeDescription = previousTimeRange.generateDescription(referenceCalendar: currentCalendar)
        } else {
            self.previousTimeRange = nil
            self.previousRangeDescription = nil
        }
    }
}
