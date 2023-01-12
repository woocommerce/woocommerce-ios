import Foundation

/// Responsible for defining two ranges of data, one starting from the the first second of the current day
/// until the same day in the current time and the previous one, starting from the first second of
/// yesterday until the same time of that day. E. g.
///
/// Today: 29 Jul 11:30 AM 2022
///
/// Current range: Jul 29 00:00 until Jul 29 23:59, 2022
/// Formatted current range for UI: Jul 29, 2022
///
/// Previous range: Jul 28 00:00 until Jul 28 11:30 AM, 2022
/// Formatted previous range for UI: Jul 28, 2022
///
/// The reason why there's a difference between the current range and the formatted current range
/// is due to the My Store rule that creates the end date far in the future for each tab instead of using today's date.
/// This behavior covers any time zone gap between the app and the store, always fetching as much data in “the future” as possible.
///
/// For data consistency, the Analytics Hub should follow the same for this range,
/// but only for the current one, the previous should remain using the today's date as the reference for the end date. 
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
