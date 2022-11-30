import Foundation

final class AnalyticsHubYearRangeSelection: AnalyticsHubTimeRangeSelectionDelegate {
    var currentTimeRange: AnalyticsHubTimeRange?
    var previousTimeRange: AnalyticsHubTimeRange?
    var currentRangeDescription: String?
    var previousRangeDescription: String?

    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = TimeZone.autoupdatingCurrent

        if let currentYearStart = referenceDate.startOfYear(timezone: currentTimezone) {
            let currentTimeRange = AnalyticsHubTimeRange(start: currentYearStart, end: referenceDate)
            self.currentTimeRange = currentTimeRange
            self.currentRangeDescription = currentTimeRange.generateDescription(referenceCalendar: currentCalendar)
        } else {
            self.currentTimeRange = nil
            self.currentRangeDescription = nil
        }

        if let oneYearAgo = currentCalendar.date(byAdding: .year, value: -1, to: referenceDate),
           let previousYearStart = oneYearAgo.startOfYear(timezone: currentTimezone) {
            let previousTimeRange = AnalyticsHubTimeRange(start: previousYearStart, end: oneYearAgo)
            self.previousTimeRange = previousTimeRange
            self.previousRangeDescription = previousTimeRange.generateDescription(referenceCalendar: currentCalendar)
        } else {
            self.previousTimeRange = nil
            self.previousRangeDescription = nil
        }
    }
}
