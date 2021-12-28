/// Represents the date range for Analytics.
/// This is a local property and not in the remote response.
///
/// - today: hourly data starting midnight today until now.
/// - yesterday: hourly data starting midnight yesterday until 23:59:59 of yesterday.
/// - lastWeek: daily data starting Sunday of previous week until 23:59:59 of the following Saturday.
/// - lastMonth: daily data starting 1st of previous month until the last day of previous month.
/// - lastQuarter: monthly data showing the previous quarter (e.g if right now is December 12, the last quarter will be Jul 1 - Sep 30).
/// - lastYear: monthly data starting January of the previous year until December of the previous year.
/// - weekToDate: daily data starting Sunday of this week until now.
/// - monthToDate: daily data starting 1st of this month until now.
/// - quarterToDate: monthly data showing the current quarter until now (e.g if right now is December 12, the last quarter will be Oct 1 - December 12).
/// - yearToDate: monthly data starting January of this year until now.
public enum AnalyticsRange: String {
    case today
    case yesterday
    case lastWeek
    case lastMonth
    case lastQuarter
    case lastYear
    case weekToDate
    case monthToDate
    case quarterToDate
    case yearToDate
}
