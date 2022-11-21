import Yosemite

class AnalyticsHubViewModel: ObservableObject {
    let analyticsTimeRange: AnalyticsHubTimeRange

    init(selectedTimeRange: StatsTimeRangeV4) {
        switch selectedTimeRange {
        case .today:
            analyticsTimeRange = AnalyticsHubTimeRange(selectionType: .today)
        case .thisWeek:
            analyticsTimeRange = AnalyticsHubTimeRange(selectionType: .weekToDate)
        case .thisMonth:
            analyticsTimeRange = AnalyticsHubTimeRange(selectionType: .monthToDate)
        case .thisYear:
            analyticsTimeRange = AnalyticsHubTimeRange(selectionType: .yearToDate)
        }
    }
}
