import Foundation

/// Responsible for defining two ranges of data, one starting from January 1st  of the current year
/// until the current date and the previous one, starting from January 1st of the last year
/// until the same day on the in that year. E. g.
///
/// Today: 1 Jul 2022
///
/// Current range: Jan 1 until Dec 31, 2022
/// Formatted current range for UI: Jan 1 until Jul 1, 2022
/// 
/// Previous range: Jan 1 until Jul 1, 2021
/// Formatted previous range for UI: Jan 1 until Jul 1, 2021
///
/// The reason why there's a difference between the current range and the formatted current range
/// is due to the My Store rule that creates the end date far in the future for each tab instead of using today's date.
/// This behavior covers any time zone gap between the app and the store, always fetching as much data in “the future” as possible.
///
/// For data consistency, the Analytics Hub should follow the same for this range,
/// but only for the current one, the previous should remain using the today's date as the reference for the end date. 
///
struct AnalyticsHubYearToDateRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let formattedCurrentRange: String?

    let previousDateStart: Date?
    let previousDateEnd: Date?
    let formattedPreviousRange: String?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        self.currentDateEnd = referenceDate.endOfYear(timezone: timezone)
        self.currentDateStart = referenceDate.startOfYear(timezone: timezone)
        self.formattedCurrentRange = currentDateStart?.formatAsRange(with: referenceDate, timezone: timezone, calendar: calendar)

        let previousDateEnd = calendar.date(byAdding: .year, value: -1, to: referenceDate)
        self.previousDateEnd = previousDateEnd
        self.previousDateStart = previousDateEnd?.startOfYear(timezone: timezone)
        self.formattedPreviousRange = previousDateStart?.formatAsRange(with: previousDateEnd, timezone: timezone, calendar: calendar)
    }
}
