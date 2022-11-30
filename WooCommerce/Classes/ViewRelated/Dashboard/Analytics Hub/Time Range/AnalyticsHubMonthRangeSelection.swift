import Foundation

final class AnalyticsHubMonthRangeSelection: AnalyticsHubTimeRangeSelectionDelegate {
    var currentTimeRange: AnalyticsHubTimeRange?
    var previousTimeRange: AnalyticsHubTimeRange?
    var currentRangeDescription: String?
    var previousRangeDescription: String?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = TimeZone.autoupdatingCurrent

        if let currentMonthStart = referenceDate.startOfMonth(timezone: currentTimezone) {
            let currentTimeRange = AnalyticsHubTimeRange(start: currentMonthStart, end: referenceDate)
            self.currentTimeRange = currentTimeRange
            self.currentRangeDescription = currentTimeRange.generateDescription(referenceCalendar: currentCalendar)
        } else {
            self.currentTimeRange = nil
            self.currentRangeDescription = nil
        }

        if let oneMonthAgo = currentCalendar.date(byAdding: .month, value: -1, to: referenceDate),
           let previousMonthStart = oneMonthAgo.startOfMonth(timezone: currentTimezone) {
            let previousTimeRange = AnalyticsHubTimeRange(start: previousMonthStart, end: oneMonthAgo)
            self.previousTimeRange = previousTimeRange
            self.previousRangeDescription = previousTimeRange.generateDescription(referenceCalendar: currentCalendar)
        } else {
            self.previousTimeRange = nil
            self.previousRangeDescription = nil
        }
    }
}
