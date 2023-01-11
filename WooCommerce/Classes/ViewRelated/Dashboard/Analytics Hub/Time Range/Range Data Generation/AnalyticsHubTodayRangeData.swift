import Foundation

/// Responsible for defining two ranges of data, one starting from the the first second of the current day
/// until the same day in the current time and the previous one, starting from the first second of
/// yesterday until the same time of that day. E. g.
///
/// Today: 29 Jul 2022
/// Current range: Jul 29 until Jul 29, 2022
/// Previous range: Jul 28 until Jul 28, 2022
///
struct AnalyticsHubTodayRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let formattedCurrentRange: String?

    let previousDateStart: Date?
    let previousDateEnd: Date?
    let formattedPreviousRange: String?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.currentDateEnd = referenceDate.endOfDay(timezone: timezone)
        self.currentDateStart = referenceDate.startOfDay(timezone: timezone)
        self.formattedCurrentRange = referenceDate.formatAsRange(timezone: timezone, calendar: calendar)

        let previousDateEnd = calendar.date(byAdding: .day, value: -1, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfDay(timezone: timezone)
        self.formattedPreviousRange = previousDateEnd?.formatAsRange(timezone: timezone, calendar: calendar)
    }
}
