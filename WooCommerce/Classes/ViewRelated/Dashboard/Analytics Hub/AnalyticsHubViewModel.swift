import Yosemite

class AnalyticsHubViewModel: ObservableObject {
    let analyticsTimeRange: AnalyticsHubTimeRange

    init(selectedTimeRange: StatsTimeRangeV4) {
        analyticsTimeRange = selectedTimeRange.toAnalyticsHubTimeRange()
    }
}

private extension StatsTimeRangeV4 {
    func toAnalyticsHubTimeRange() -> AnalyticsHubTimeRange {
        switch self {
        case .today:
            return AnalyticsHubTimeRange(selectionType: .today)
        case .thisWeek:
            return AnalyticsHubTimeRange(selectionType: .weekToDate)
        case .thisMonth:
            return AnalyticsHubTimeRange(selectionType: .monthToDate)
        case .thisYear:
            return AnalyticsHubTimeRange(selectionType: .yearToDate)
        }
    }
}
