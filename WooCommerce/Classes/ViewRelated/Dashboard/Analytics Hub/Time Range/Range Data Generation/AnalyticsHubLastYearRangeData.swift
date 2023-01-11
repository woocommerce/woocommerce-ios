import Foundation

/// Responsible for defining two ranges of data, one starting from January 1st of the last year
/// until December 31th of that same year, and the previous one as two years ago, also ranging
/// all days of that year. E. g.
///
/// Today: 29 Jul 2022
/// Current range: Jan 1 until Dec 31, 2021
/// Previous range: Jan 1 until Dec 31, 2020
///
struct AnalyticsHubLastYearRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let formattedCurrentRange: String?

    let previousDateStart: Date?
    let previousDateEnd: Date?
    let formattedPreviousRange: String?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: referenceDate)
        self.currentDateEnd = oneYearAgo?.endOfYear(timezone: timezone)
        self.currentDateStart = oneYearAgo?.startOfYear(timezone: timezone)
        self.formattedCurrentRange = currentDateStart?.formatAsRange(with: currentDateEnd, timezone: timezone, calendar: calendar)

        let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: referenceDate)
        self.previousDateEnd = twoYearsAgo?.endOfYear(timezone: timezone)
        self.previousDateStart = twoYearsAgo?.startOfYear(timezone: timezone)
        self.formattedPreviousRange = previousDateStart?.formatAsRange(with: previousDateEnd, timezone: timezone, calendar: calendar)
    }
}
