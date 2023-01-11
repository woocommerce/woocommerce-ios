import Foundation

/// Responsible for defining two ranges of data, one starting from the first day of the last month
/// until the final day of that same month, and the previous one as two months ago, also starting
/// from the first day until the final day of that month. E. g.
///
/// Today: 29 Jul 2022
/// Current range: Jun 1 until Jun 30, 2022
/// Previous range: May 1 until May 31, 2022
///
struct AnalyticsHubLastMonthRangeData: AnalyticsHubTimeRangeData {
    let currentDateStart: Date?
    let currentDateEnd: Date?
    let formattedCurrentRange: String?

    let previousDateStart: Date?
    let previousDateEnd: Date?
    let formattedPreviousRange: String?

    init(referenceDate: Date, timezone: TimeZone, calendar: Calendar) {
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: referenceDate)
        self.currentDateEnd = oneMonthAgo?.endOfMonth(timezone: timezone)
        self.currentDateStart = oneMonthAgo?.startOfMonth(timezone: timezone)
        self.formattedCurrentRange = currentDateStart?.formatAsRange(with: currentDateEnd, timezone: timezone, calendar: calendar)

        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: referenceDate)
        self.previousDateEnd = twoMonthsAgo?.endOfMonth(timezone: timezone)
        self.previousDateStart = twoMonthsAgo?.startOfMonth(timezone: timezone)
        self.formattedPreviousRange = previousDateStart?.formatAsRange(with: previousDateEnd, timezone: timezone, calendar: calendar)
    }
}
