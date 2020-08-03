/// Represents the time range for an Order Stats v4 model.
/// This is a local property and not in the remote response.
///
/// - today: hourly data starting midnight today until now.
/// - thisWeek: daily data starting Sunday of this week until now.
/// - thisMonth: daily data starting 1st of this month until now.
/// - thisYear: monthly data starting January of this year until now.
public enum StatsTimeRangeV4: String {
    case today
    case thisWeek
    case thisMonth
    case thisYear
}

extension StatsTimeRangeV4 {
    /// Represents the period unit of the store stats using Stats v4 API given a time range.
    public var intervalGranularity: StatsGranularityV4 {
        switch self {
        case .today:
            return .hourly
        case .thisWeek:
            return .daily
        case .thisMonth:
            return .daily
        case .thisYear:
            return .monthly
        }
    }

    /// Represents the period unit of the site visit stats given a time range.
    public var siteVisitStatsGranularity: StatGranularity {
        switch self {
        case .today, .thisWeek, .thisMonth:
            return .day
        case .thisYear:
            return .month
        }
    }

    /// Represents the period unit of the top earners stats given a time range.
    public var topEarnerStatsGranularity: StatGranularity {
        switch self {
        case .today:
            return .day
        case .thisWeek:
            return .week
        case .thisMonth:
            return .month
        case .thisYear:
            return .year
        }
    }

    /// Represents the period unit of the leaderboards v4 API  given a time range.
    public var leaderboardsGranularity: StatsGranularityV4 {
        switch self {
        case .today:
            return .daily
        case .thisWeek:
            return .weekly
        case .thisMonth:
            return .monthly
        case .thisYear:
            return .yearly
        }
    }

    /// The number of intervals for site visit stats to fetch given a time range.
    /// The interval unit is in `siteVisitStatsGranularity`.
    func siteVisitStatsQuantity(date: Date, siteTimezone: TimeZone) -> Int {
        switch self {
        case .today:
            return 1
        case .thisWeek:
            return 7
        case .thisMonth:
            var calendar = Calendar.current
            calendar.timeZone = siteTimezone
            let daysThisMonth = calendar.range(of: .day, in: .month, for: date)
            return daysThisMonth?.count ?? 0
        case .thisYear:
            return 12
        }
    }
}
