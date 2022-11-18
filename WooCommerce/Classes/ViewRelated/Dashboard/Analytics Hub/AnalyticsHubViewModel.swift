import Yosemite

class AnalyticsHubViewModel: ObservableObject {
    let selectedTimeRange: StatsTimeRangeV4

    init(selectedTimeRange: StatsTimeRangeV4) {
        self.selectedTimeRange = selectedTimeRange
    }
}
