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
         statsTimeRange: StatsTimeRangeV4,
         stores: StoresManager = ServiceLocator.stores) {
        let selectedType = AnalyticsHubTimeRangeSelection.SelectionType(statsTimeRange)
        let timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: selectedType)

        self.siteID = siteID
        self.stores = stores
        self.timeRangeSelectionType = selectedType
        self.timeRangeSelection = timeRangeSelection
        self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeSelection: timeRangeSelection)

        bindViewModelsWithData()
    }

    /// Revenue Card ViewModel
    ///
    @Published var revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: nil, previousPeriodStats: nil)

    /// Orders Card ViewModel
    ///
    @Published var ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: nil, previousPeriodStats: nil)

    /// Products Card ViewModel
    ///
    @Published var productCard = AnalyticsHubViewModel.productCard(currentPeriodStats: nil, previousPeriodStats: nil, itemsSoldStats: nil)

    /// Time Range Selection Type
    ///
    @Published var timeRangeSelectionType: AnalyticsHubTimeRangeSelection.SelectionType

    /// Time Range ViewModel
    ///
    @Published var timeRangeCard: AnalyticsTimeRangeCardViewModel

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

    /// Whether selecting a time range failed
    ///
    @Published private(set) var errorSelectingTimeRange: Bool = false

    // MARK: Private data

    /// Order stats for the current selected time period
    ///
    @Published private var currentOrderStats: OrderStatsV4? = nil

    /// Order stats for the previous time period (for comparison)
    ///
    @Published private var previousOrderStats: OrderStatsV4? = nil

    /// Stats for the current top items sold. Used in the products card.
    ///
    @Published private var itemsSoldStats: TopEarnerStats? = nil

    /// Time Range selection data defining the current and previous time period
    ///
    private var timeRangeSelection: AnalyticsHubTimeRangeSelection

    /// Request stats data from network
    ///
    @MainActor
    func updateData() async {
        do {
            try await retrieveOrderStats()
        } catch is AnalyticsHubTimeRangeSelection.TimeRangeGeneratorError {
            notice = Notice(title: Localization.timeRangeGeneratorError, feedbackType: .error)
            errorSelectingTimeRange = true
            DDLogWarn("⚠️ Error selecting analytics time range: \(timeRangeSelectionType.description)")
        } catch {
            switchToErrorState()
            DDLogWarn("⚠️ Error fetching analytics data: \(error)")
        }
    }
}

// MARK: Networking
private extension AnalyticsHubViewModel {

    @MainActor
    func retrieveOrderStats() async throws {
        switchToLoadingState()

        let currentTimeRange = try timeRangeSelection.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRangeSelection.unwrapPreviousTimeRange()

        async let currentPeriodRequest = retrieveStats(earliestDateToInclude: currentTimeRange.start,
                                                       latestDateToInclude: currentTimeRange.end,
                                                       forceRefresh: true)
        async let previousPeriodRequest = retrieveStats(earliestDateToInclude: previousTimeRange.start,
                                                        latestDateToInclude: previousTimeRange.end,
                                                        forceRefresh: true)

        async let itemsSoldRequest = retrieveTopItemsSoldStats(earliestDateToInclude: currentTimeRange.start,
                                                               latestDateToInclude: currentTimeRange.end,
                                                               forceRefresh: true)

        let (currentPeriodStats, previousPeriodStats, itemsSoldStats) = try await (currentPeriodRequest, previousPeriodRequest, itemsSoldRequest)
        self.currentOrderStats = currentPeriodStats
        self.previousOrderStats = previousPeriodStats
        self.itemsSoldStats = itemsSoldStats
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

    @MainActor
    /// Retrieves top ItemsSold stats using the `retrieveTopEarnerStats` action but without saving results into storage.
    ///
    func retrieveTopItemsSoldStats(earliestDateToInclude: Date, latestDateToInclude: Date, forceRefresh: Bool) async throws -> TopEarnerStats {
        try await withCheckedThrowingContinuation { continuation in
            let action = StatsActionV4.retrieveTopEarnerStats(siteID: siteID,
                                                              timeRange: .thisYear, // Only needed for storing purposes, we can ignore it.
                                                              earliestDateToInclude: earliestDateToInclude,
                                                              latestDateToInclude: latestDateToInclude,
                                                              quantity: Constants.maxNumberOfTopItemsSold,
                                                              forceRefresh: forceRefresh,
                                                              saveInStorage: false,
                                                              onCompletion: { result in
                continuation.resume(with: result)
            })
            stores.dispatch(action)
        }
    }
}

// MARK: Data - UI mapping
private extension AnalyticsHubViewModel {

    func switchToLoadingState() {
        self.revenueCard = revenueCard.redacted
        self.ordersCard = ordersCard.redacted
        self.productCard = productCard.redacted
    }

    func switchToErrorState() {
        self.currentOrderStats = nil
        self.previousOrderStats = nil
        self.itemsSoldStats = nil
    }

    func bindViewModelsWithData() {
        Publishers.CombineLatest3($currentOrderStats, $previousOrderStats, $itemsSoldStats)
            .sink { [weak self] currentOrderStats, previousOrderStats, itemsSoldStats in
                guard let self else { return }

                self.revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.productCard = AnalyticsHubViewModel.productCard(currentPeriodStats: currentOrderStats,
                                                                     previousPeriodStats: previousOrderStats,
                                                                     itemsSoldStats: itemsSoldStats)

            }.store(in: &subscriptions)

        $timeRangeSelectionType
            .removeDuplicates()
            .sink { [weak self] newSelectionType in
                guard let self else { return }
                self.timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: newSelectionType)
                self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeSelection: self.timeRangeSelection)
                Task.init {
                    await self.updateData()
                }
            }.store(in: &subscriptions)
    }

    static func revenueCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardViewModel {
        let showSyncError = currentPeriodStats == nil || previousPeriodStats == nil
        let totalDelta = StatsDataTextFormatter.createTotalRevenueDelta(from: previousPeriodStats, to: currentPeriodStats)
        let netDelta = StatsDataTextFormatter.createNetRevenueDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsReportCardViewModel(title: Localization.RevenueCard.title,
                                            leadingTitle: Localization.RevenueCard.leadingTitle,
                                            leadingValue: StatsDataTextFormatter.createTotalRevenueText(orderStats: currentPeriodStats,
                                                                                                        selectedIntervalIndex: nil),
                                            leadingDelta: totalDelta.string,
                                            leadingDeltaColor: Constants.deltaColor(for: totalDelta.direction),
                                            leadingChartData: StatsIntervalDataParser.getChartData(for: .totalRevenue, from: currentPeriodStats),
                                            trailingTitle: Localization.RevenueCard.trailingTitle,
                                            trailingValue: StatsDataTextFormatter.createNetRevenueText(orderStats: currentPeriodStats),
                                            trailingDelta: netDelta.string,
                                            trailingDeltaColor: Constants.deltaColor(for: netDelta.direction),
                                            trailingChartData: StatsIntervalDataParser.getChartData(for: .netRevenue, from: currentPeriodStats),
                                            isRedacted: false,
                                            showSyncError: showSyncError,
                                            syncErrorMessage: Localization.RevenueCard.noRevenue)
    }

    static func ordersCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardViewModel {
        let showSyncError = currentPeriodStats == nil || previousPeriodStats == nil
        let ordersCountDelta = StatsDataTextFormatter.createOrderCountDelta(from: previousPeriodStats, to: currentPeriodStats)
        let orderValueDelta = StatsDataTextFormatter.createAverageOrderValueDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsReportCardViewModel(title: Localization.OrderCard.title,
                                            leadingTitle: Localization.OrderCard.leadingTitle,
                                            leadingValue: StatsDataTextFormatter.createOrderCountText(orderStats: currentPeriodStats,
                                                                                                      selectedIntervalIndex: nil),
                                            leadingDelta: ordersCountDelta.string,
                                            leadingDeltaColor: Constants.deltaColor(for: ordersCountDelta.direction),
                                            leadingChartData: StatsIntervalDataParser.getChartData(for: .orderCount, from: currentPeriodStats),
                                            trailingTitle: Localization.OrderCard.trailingTitle,
                                            trailingValue: StatsDataTextFormatter.createAverageOrderValueText(orderStats: currentPeriodStats),
                                            trailingDelta: orderValueDelta.string,
                                            trailingDeltaColor: Constants.deltaColor(for: orderValueDelta.direction),
                                            trailingChartData: StatsIntervalDataParser.getChartData(for: .averageOrderValue, from: currentPeriodStats),
                                            isRedacted: false,
                                            showSyncError: showSyncError,
                                            syncErrorMessage: Localization.OrderCard.noOrders)
    }

    /// Helper function to create a `AnalyticsProductCardViewModel` from the fetched stats.
    ///
    static func productCard(currentPeriodStats: OrderStatsV4?,
                            previousPeriodStats: OrderStatsV4?,
                            itemsSoldStats: TopEarnerStats?) -> AnalyticsProductCardViewModel {
        let showStatsError = currentPeriodStats == nil || previousPeriodStats == nil
        let showItemsSoldError = itemsSoldStats == nil
        let itemsSold = StatsDataTextFormatter.createItemsSoldText(orderStats: currentPeriodStats)
        let itemsSoldDelta = StatsDataTextFormatter.createOrderItemsSoldDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsProductCardViewModel(itemsSold: itemsSold,
                                             delta: itemsSoldDelta.string,
                                             deltaBackgroundColor: Constants.deltaColor(for: itemsSoldDelta.direction),
                                             itemsSoldData: itemSoldRows(from: itemsSoldStats),
                                             isRedacted: false,
                                             showStatsError: showStatsError,
                                             showItemsSoldError: showItemsSoldError)
    }

    /// Helper functions to create `TopPerformersRow.Data` items rom the provided `TopEarnerStats`.
    ///
    static func itemSoldRows(from itemSoldStats: TopEarnerStats?) -> [TopPerformersRow.Data] {
        guard let items = itemSoldStats?.items else {
            return []
        }

        return items.map { item in
            TopPerformersRow.Data(imageURL: URL(string: item.imageUrl ?? ""),
                                  name: item.productName ?? "",
                                  details: Localization.ProductCard.netSales(value: item.totalString),
                                  value: "\(item.quantity)")
        }
    }

    static func timeRangeCard(timeRangeSelection: AnalyticsHubTimeRangeSelection) -> AnalyticsTimeRangeCardViewModel {
        return AnalyticsTimeRangeCardViewModel(selectedRangeTitle: timeRangeSelection.rangeSelectionDescription,
                                               currentRangeSubtitle: timeRangeSelection.currentRangeDescription,
                                               previousRangeSubtitle: timeRangeSelection.previousRangeDescription)
    }
}

// MARK: - Constants
private extension AnalyticsHubViewModel {
    enum Constants {
        static let maxNumberOfTopItemsSold = 5

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
            static let noRevenue = NSLocalizedString("Unable to load revenue analytics",
                                                     comment: "Text displayed when there is an error loading revenue stats data.")
        }

        enum OrderCard {
            static let title = NSLocalizedString("ORDERS", comment: "Title for order analytics section in the Analytics Hub")
            static let leadingTitle = NSLocalizedString("Total Orders", comment: "Label for total number of orders in the Analytics Hub")
            static let trailingTitle = NSLocalizedString("Average Order Value", comment: "Label for average value of orders in the Analytics Hub")
            static let noOrders = NSLocalizedString("Unable to load order analytics",
                                                    comment: "Text displayed when there is an error loading order stats data.")
        }

        enum ProductCard {
            static func netSales(value: String) -> String {
                String.localizedStringWithFormat(NSLocalizedString("Net sales: %@", comment: "Label for the total sales of a product in the Analytics Hub"),
                                                 value)
            }
        }

        static let timeRangeGeneratorError = NSLocalizedString("Sorry, something went wrong. We can't load analytics for the selected date range.",
                                                               comment: "Error shown when there is a problem retrieving the dates for the selected date range.")
    }
}
