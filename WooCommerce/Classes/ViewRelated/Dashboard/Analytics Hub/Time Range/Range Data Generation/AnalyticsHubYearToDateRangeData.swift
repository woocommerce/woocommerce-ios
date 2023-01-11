import Foundation

/// Responsible for defining two ranges of data, one starting from January 1st  of the current year
/// until the current date and the previous one, starting from January 1st of the last year
/// until the same day on the in that year. E. g.
///
/// Today: 1 Jul 2022
/// Current range: Jan 1 until Jul 1, 2022
/// Previous range: Jan 1 until Jul 1, 2022
///
struct AnalyticsHubYearToDateRangeData: AnalyticsHubTimeRangeData {
    let referenceDate: Date?

    let currentDateStart: Date?
    let currentDateEnd: Date?
    let formattedCurrentRange: String?

    let previousDateStart: Date?
    let previousDateEnd: Date?
    let formattedPreviousRange: String?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.referenceDate = referenceDate
        self.currentDateEnd = referenceDate.endOfYear(timezone: timezone)
        self.currentDateStart = referenceDate.startOfYear(timezone: timezone)
        self.formattedCurrentRange = DateFormatter.Stats.formatAsRange(using: currentDateStart, and: referenceDate, timezone: timezone, calendar: calendar)

        let previousDateEnd = calendar.date(byAdding: .year, value: -1, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfYear(timezone: timezone)
        self.formattedPreviousRange = DateFormatter.Stats.formatAsRange(using: previousDateStart, and: previousDateEnd, timezone: timezone, calendar: calendar)
    }
}
