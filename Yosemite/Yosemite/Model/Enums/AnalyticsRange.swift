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

extension AnalyticsRange {


    /// Represents the period unit of the store stats using Stats v4 API given a time range.
    public var intervalGranularity: StatsGranularityV4 {
        switch self {
        case .today:
        return .hourly
        case .yesterday:
        return .hourly
        case .lastWeek:
        return .daily
        case .lastMonth:
        return .daily
        case .lastQuarter:
        return .monthly
        case .lastYear:
        return .monthly
        case .weekToDate:
        return .daily
        case .monthToDate:
        return .daily
        case .quarterToDate:
        return .monthly
        case .yearToDate:
        return .monthly
        }
    }

    /// Represents the period unit of the site visit stats given a time range.
    public var siteVisitStatsGranularity: StatGranularity {
        switch self {
        case .today, .yesterday, .lastWeek, .lastMonth, .lastQuarter, .weekToDate, .monthToDate, .quarterToDate:
            return .day
        case .lastYear, .yearToDate:
            return .month
        }
    }

    /// Represents the period unit of the top earners stats given a time range.
    public var topEarnerStatsGranularity: StatGranularity {
        switch self {
        case .today:
        return .day
        case .yesterday:
        return .day
        case .lastWeek:
        return .week
        case .lastMonth:
        return .month
        case .lastQuarter:
        return .month
        case .lastYear:
        return .year
        case .weekToDate:
        return .week
        case .monthToDate:
        return .month
        case .quarterToDate:
        return .month
        case .yearToDate:
        return .year
        }
    }

    /// Represents the period unit of the leaderboards v4 API  given a time range.
    public var leaderboardsGranularity: StatsGranularityV4 {
        switch self {
        case .today:
        return .daily
        case .yesterday:
        return .daily
        case .lastWeek:
        return .weekly
        case .lastMonth:
        return .monthly
        case .lastQuarter:
        return .monthly
        case .lastYear:
        return .yearly
        case .weekToDate:
        return .weekly
        case .monthToDate:
        return .monthly
        case .quarterToDate:
        return .monthly
        case .yearToDate:
        return .yearly
        }
    }

    /// The number of intervals for site visit stats to fetch given a time range.
    /// The interval unit is in `siteVisitStatsGranularity`.
    func siteVisitStatsQuantity(date: Date, siteTimezone: TimeZone) -> Int {
        switch self {
        case .today:
        return 1
        case .yesterday:
        return 1
        case .lastWeek:
        return 7
        case .lastMonth:
            var calendar = Calendar.current
            calendar.timeZone = siteTimezone
            let daysThisMonth = calendar.range(of: .day, in: .month, for: date)
            return daysThisMonth?.count ?? 0
        case .lastQuarter:
        return 4
        case .lastYear:
        return 12
        case .weekToDate:
        return 7
        case .monthToDate:
            var calendar = Calendar.current
            calendar.timeZone = siteTimezone
            let daysThisMonth = calendar.range(of: .day, in: .month, for: date)
            return daysThisMonth?.count ?? 0
        case .quarterToDate:
        return 4
        case .yearToDate:
        return 12
        }
    }
}

private extension AnalyticsRange {
    enum Localization {
        static let today = NSLocalizedString("Today", comment: "Title of today date range.")
        static let yesterday = NSLocalizedString("Yesterday", comment: "Title of yesterday date range.")
        static let lastWeek = NSLocalizedString("Last Week", comment: "Title of yesterday date range.")
        static let lastMonth = NSLocalizedString("Last Month", comment: "Title of last month date range.")
        static let lastQuarter = NSLocalizedString("Last Quarter", comment: "Title of last quarter date range.")
        static let lastYear = NSLocalizedString("Last Year", comment: "Title of last year date range.")
        static let weekToDate = NSLocalizedString("Week to date", comment: "Title of week to date date range.")
        static let monthToDate = NSLocalizedString("Month to date", comment: "Title of month to date date range.")
        static let quarterToDate = NSLocalizedString("Quarter to date", comment: "Title of quarter to date date range.")
        static let yearToDate = NSLocalizedString("Year to date", comment: "Title of year to date date range.")
    }
}
