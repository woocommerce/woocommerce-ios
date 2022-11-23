import Foundation
import Yosemite

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    /// Revenue Card ViewModel
    ///
    @Published var revenueCard = AnalyticsReportCardViewModel(title: "REVENUE",
                                                              leadingTitle: "Total Sales",
                                                              leadingValue: "$3.234",
                                                              leadingDelta: "+23%",
                                                              leadingDeltaColor: .withColorStudio(.green, shade: .shade50),
                                                              trailingTitle: "Net Sales",
                                                              trailingValue: "$2.324",
                                                              trailingDelta: "-4%",
                                                              trailingDeltaColor: .withColorStudio(.red, shade: .shade40))

    /// Orders Card ViewModel
    ///
    @Published var ordersCard = AnalyticsReportCardViewModel(title: "ORDERS",
                                                             leadingTitle: "Total Orders",
                                                             leadingValue: "145",
                                                             leadingDelta: "+36%",
                                                             leadingDeltaColor: .withColorStudio(.green, shade: .shade50),
                                                             trailingTitle: "Average Order Value",
                                                             trailingValue: "$57,99",
                                                             trailingDelta: "-16%",
                                                             trailingDeltaColor: .withColorStudio(.red, shade: .shade40))

    @Published var timeRangeCard: AnalyticsTimeRangeCardViewModel
    
    /// Current Time Range controlling the Analytics Hub
    ///
    private var currentTimeRange: AnalyticsHubTimeRange

    init(statsTimeRange: StatsTimeRangeV4) {
        self.currentTimeRange = AnalyticsHubTimeRange(selectedTimeRange: statsTimeRange)
        self.timeRangeCard = AnalyticsTimeRangeCardViewModel(selectedRangeTitle: currentTimeRange.selectionDescription,
                                                             currentRangeSubtitle: currentTimeRange.currentRangeDescription,
                                                             previousRangeSubtitle: currentTimeRange.previousRangeDescription)
    }
}
