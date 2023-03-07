import Foundation

/// Responsible for defining two ranges of data based on user provided dates.
/// The current range will be what user provided.
/// The previous range will be a range of the same length ending on the day before the current range starts.
///
/// Current range: Jan 5 - Jan 7, 2022
/// Previous range: Jan 2 - Jan 4, 2022
///
struct AnalyticsHubCustomRangeData: AnalyticsHubTimeRangeData {
    var currentDateStart: Date?
    var currentDateEnd: Date?
    var formattedCurrentRange: String?

    var previousDateStart: Date?
    var previousDateEnd: Date?
    var formattedPreviousRange: String?

    init(start: Date, end: Date, timezone: TimeZone, calendar: Calendar) {
        guard
            let dayDifference = calendar.dateComponents([.day], from: start, to: end).day,
            let previousEnd = calendar.date(byAdding: .day, value: -1, to: start),
            let previousStart = calendar.date(byAdding: .day, value: -dayDifference, to: previousEnd) else {
            return
        }
        self.currentDateStart = start.startOfDay(timezone: timezone)
        self.currentDateEnd = end.endOfDay(timezone: timezone)
        self.formattedCurrentRange = currentDateStart?.formatAsRange(with: currentDateEnd, timezone: timezone, calendar: calendar)

        self.previousDateStart = previousStart.startOfDay(timezone: timezone)
        self.previousDateEnd = previousEnd.startOfDay(timezone: timezone)
        self.formattedPreviousRange = previousDateStart?.formatAsRange(with: previousDateEnd, timezone: timezone, calendar: calendar)
    }
}
