import Yosemite

class AnalyticsHubViewModel: ObservableObject {
    private let selectedTimeRange: StatsTimeRangeV4?

    init(selectedTimeRange: StatsTimeRangeV4?) {
        self.selectedTimeRange = selectedTimeRange
    }
}
