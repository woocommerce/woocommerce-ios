import Foundation
import Yosemite
import Combine
import class UIKit.UIColor

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager

    private var subscriptions = Set<AnyCancellable>()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores

        bindViewModelsWithData()
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
    @Published var revenueCard = AnalyticsReportCardViewModel(title: Localization.RevenueCard.title,
                                                              leadingTitle: Localization.RevenueCard.leadingTitle,
                                                              leadingValue: Constants.placeholderValue,
                                                              leadingDelta: Constants.placeholderDelta.string,
                                                              leadingDeltaColor: Constants.deltaColor(for: Constants.placeholderDelta.direction),
                                                              trailingTitle: Localization.RevenueCard.trailingTitle,
                                                              trailingValue: Constants.placeholderValue,
                                                              trailingDelta: Constants.placeholderDelta.string,
                                                              trailingDeltaColor: Constants.deltaColor(for: Constants.placeholderDelta.direction))

    /// Orders Card ViewModel
    ///
    @Published var ordersCard = AnalyticsReportCardViewModel(title: Localization.OrderCard.title,
                                                             leadingTitle: Localization.OrderCard.leadingTitle,
                                                             leadingValue: Constants.placeholderValue,
                                                             leadingDelta: Constants.placeholderDelta.string,
                                                             leadingDeltaColor: Constants.deltaColor(for: Constants.placeholderDelta.direction),
                                                             trailingTitle: Localization.OrderCard.trailingTitle,
                                                             trailingValue: Constants.placeholderValue,
                                                             trailingDelta: Constants.placeholderDelta.string,
                                                             trailingDeltaColor: Constants.deltaColor(for: Constants.placeholderDelta.direction))

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

private extension AnalyticsHubViewModel {

    func bindViewModelsWithData() {
        Publishers.CombineLatest($currentOrderStats, $previousOrderStats)
            .sink { [weak self] currentOrderStats, previousOrderStats in
                guard let self else { return }

                self.revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
            }.store(in: &subscriptions)
    }

    static func revenueCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardViewModel {
        let totalDelta = StatsDataTextFormatter.createTotalRevenueDelta(from: previousPeriodStats, to: currentPeriodStats)
        let netDelta = StatsDataTextFormatter.createNetRevenueDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsReportCardViewModel(title: Localization.RevenueCard.title,
                                            leadingTitle: Localization.RevenueCard.leadingTitle,
                                            leadingValue: StatsDataTextFormatter.createTotalRevenueText(orderStats: currentPeriodStats,
                                                                                                        selectedIntervalIndex: nil),
                                            leadingDelta: totalDelta.string,
                                            leadingDeltaColor: Constants.deltaColor(for: totalDelta.direction),
                                            trailingTitle: Localization.RevenueCard.trailingTitle,
                                            trailingValue: StatsDataTextFormatter.createNetRevenueText(orderStats: currentPeriodStats),
                                            trailingDelta: netDelta.string,
                                            trailingDeltaColor: Constants.deltaColor(for: netDelta.direction))
    }

    static func ordersCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardViewModel {
        let ordersCountDelta = StatsDataTextFormatter.createOrderCountDelta(from: previousPeriodStats, to: currentPeriodStats)
        let orderValueDelta = StatsDataTextFormatter.createAverageOrderValueDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsReportCardViewModel(title: Localization.OrderCard.title,
                                            leadingTitle: Localization.OrderCard.leadingTitle,
                                            leadingValue: StatsDataTextFormatter.createOrderCountText(orderStats: currentPeriodStats,
                                                                                                      selectedIntervalIndex: nil),
                                            leadingDelta: ordersCountDelta.string,
                                            leadingDeltaColor: Constants.deltaColor(for: ordersCountDelta.direction),
                                            trailingTitle: Localization.OrderCard.trailingTitle,
                                            trailingValue: StatsDataTextFormatter.createAverageOrderValueText(orderStats: currentPeriodStats),
                                            trailingDelta: orderValueDelta.string,
                                            trailingDeltaColor: Constants.deltaColor(for: orderValueDelta.direction))
    }
}

// MARK: - Constants
private extension AnalyticsHubViewModel {
    enum Constants {
        static let placeholderValue = "-"
        static let placeholderDelta = StatsDataTextFormatter.createDeltaPercentage(from: 0.0, to: 0.0)
        static func deltaColor(for direction: StatsDataTextFormatter.DeltaPercentage.Direction) -> UIColor {
            switch direction {
            case .positive:
                return .withColorStudio(.green, shade: .shade50)
            case .negative, .zero:
                return .withColorStudio(.red, shade: .shade40)
            }
        }
    }

    enum Localization {
        enum RevenueCard {
            static let title = NSLocalizedString("REVENUE", comment: "Title for revenue analytics section in the Analytics Hub")
            static let leadingTitle = NSLocalizedString("Total Sales", comment: "Label for total sales (gross revenue) in the Analytics Hub")
            static let trailingTitle = NSLocalizedString("Net Sales", comment: "Label for net sales (net revenue) in the Analytics Hub")
        }

        enum OrderCard {
            static let title = NSLocalizedString("ORDERS", comment: "Title for order analytics section in the Analytics Hub")
            static let leadingTitle = NSLocalizedString("Total Orders", comment: "Label for total number of orders in the Analytics Hub")
            static let trailingTitle = NSLocalizedString("Average Order Value", comment: "Label for average value of orders in the Analytics Hub")
        }
    }
}
