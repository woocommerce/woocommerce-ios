/// Represents the time range for an Order Stats v4 model.
/// This is a local property and not in the remote response.
///
/// - today: hourly data starting midnight today until now.
/// - thisWeek: daily data starting Sunday of this week until now.
/// - thisMonth: daily data starting 1st of this month until now.
/// - thisYear: monthly data starting January of this year until now.
enum StatsTimeRange: String {
    case today
    case thisWeek
    case thisMonth
    case thisYear
}

extension StatsTimeRange {
    init(_ timeRange: IntentTimeRange) {
        switch timeRange {
        case .unknown, .today:
            self = .today
        case .thisWeek:
            self = .thisWeek
        case .thisMonth:
            self = .thisMonth
        case .thisYear:
            self = .thisYear
        }
    }
}
