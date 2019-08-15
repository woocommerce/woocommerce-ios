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
}
