import Foundation

final class AnalyticsHubYearRangeSelection: AnalyticsHubTimeRangeSelection {
    var currentTimeRange: AnalyticsHubTimeRange?
    
    var previousTimeRange: AnalyticsHubTimeRange?
    
    init(referenceDate: Date, currentCalendar: Calendar) {
        let currentTimezone = TimeZone.autoupdatingCurrent
        
        if let currentYearStart = referenceDate.startOfYear(timezone: currentTimezone) {
            self.currentTimeRange = AnalyticsHubTimeRange(start: currentYearStart, end: referenceDate)
        } else {
            self.currentTimeRange = nil
        }
        
        if let oneYearAgo = currentCalendar.date(byAdding: .year, value: -1, to: referenceDate),
           let previousYearStart = oneYearAgo.startOfYear(timezone: currentTimezone) {
            self.previousTimeRange = AnalyticsHubTimeRange(start: previousYearStart, end: oneYearAgo)
        } else {
            self.previousTimeRange = nil
        }
    }
}
