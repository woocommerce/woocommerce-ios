import Foundation
import Yosemite

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores

        Task.init {
            do {
                try await retrieveOrderStats()
            } catch {
                DDLogWarn("⚠️ Error fetching analytics data: \(error)")
            }
        }
    }

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

    /// Time Range ViewModel
    ///
    @Published var timeRangeCard = AnalyticsTimeRangeCardViewModel(selectedRangeTitle: "Year to Date",
                                                                   currentRangeSubtitle: "Jan 1 - Nov 23, 2022",
                                                                   previousRangeSubtitle: "Jan 1 - Nov 23, 2021")

    // MARK: Private data

    /// Order stats for the current selected time period
    ///
    @Published private var currentOrderStats: OrderStatsV4? = nil

    /// Order stats for the previous time period (for comparison)
    ///
    @Published private var previousOrderStats: OrderStatsV4? = nil
}

private extension AnalyticsHubViewModel {

    @MainActor
    func retrieveOrderStats() async throws {
        // TODO: get dates from the selected period
        let currentMonthDate = Date()
        let previousMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!

        async let currentPeriodRequest = retrieveStats(earliestDateToInclude: currentMonthDate.startOfMonth(timezone: .current),
                                                       latestDateToInclude: currentMonthDate.endOfMonth(timezone: .current),
                                                       forceRefresh: true)
        async let previousPeriodRequest = retrieveStats(earliestDateToInclude: previousMonthDate.startOfMonth(timezone: .current),
                                                        latestDateToInclude: previousMonthDate.endOfMonth(timezone: .current),
                                                        forceRefresh: true)
        let (currentPeriodStats, previousPeriodStats) = try await (currentPeriodRequest, previousPeriodRequest)
        self.currentOrderStats = currentPeriodStats
        self.previousOrderStats = previousPeriodStats
    }

    @MainActor
    func retrieveStats(earliestDateToInclude: Date,
                       latestDateToInclude: Date,
                       forceRefresh: Bool) async throws -> OrderStatsV4 {
        try await withCheckedThrowingContinuation { continuation in
            // TODO: get unit and quantity from the selected period
            let unit: StatsGranularityV4 = .daily
            let quantity = 31

            let action = StatsActionV4.retrieveCustomStats(siteID: siteID,
                                                           unit: unit,
                                                           earliestDateToInclude: earliestDateToInclude,
                                                           latestDateToInclude: latestDateToInclude,
                                                           quantity: quantity,
                                                           forceRefresh: forceRefresh) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }
}
