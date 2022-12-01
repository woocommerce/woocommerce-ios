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
        let selectedType = AnalyticsHubTimeRangeGenerator.SelectionType.from(statsTimeRange)
        let timeRangeGenerator = AnalyticsHubTimeRangeGenerator(selectionType: selectedType)

        self.siteID = siteID
        self.stores = stores
        self.timeRangeSelectionType = selectedType
        self.timeRangeGenerator = timeRangeGenerator
        self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeGenerator: timeRangeGenerator)

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
    @Published var productCard = AnalyticsHubViewModel.productCard(currentPeriodStats: nil, previousPeriodStats: nil)

    /// Time Range Selection Type
    ///
    @Published var timeRangeSelectionType: AnalyticsHubTimeRangeGenerator.SelectionType

    /// Time Range ViewModel
    ///
    @Published var timeRangeCard: AnalyticsTimeRangeCardViewModel

    // MARK: Private data

    /// Order stats for the current selected time period
    ///
    @Published private var currentOrderStats: OrderStatsV4? = nil

    /// Order stats for the previous time period (for comparison)
    ///
    @Published private var previousOrderStats: OrderStatsV4? = nil

    /// Time Range selection data defining the current and previous time period
    ///
    private var timeRangeGenerator: AnalyticsHubTimeRangeGenerator

    /// Request stats data from network
    ///
    func updateData() async {
        do {
            try await retrieveOrderStats()
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

        let currentTimeRange = try timeRangeGenerator.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRangeGenerator.unwrapPreviousTimeRange()

        async let currentPeriodRequest = retrieveStats(earliestDateToInclude: currentTimeRange.start,
                                                       latestDateToInclude: currentTimeRange.end,
                                                       forceRefresh: true)
        async let previousPeriodRequest = retrieveStats(earliestDateToInclude: previousTimeRange.start,
                                                        latestDateToInclude: previousTimeRange.end,
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
    }

    func bindViewModelsWithData() {
        Publishers.CombineLatest($currentOrderStats, $previousOrderStats)
            .sink { [weak self] currentOrderStats, previousOrderStats in
                guard let self else { return }

                self.revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.productCard = AnalyticsHubViewModel.productCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)

            }.store(in: &subscriptions)

        $timeRangeSelectionType
            .removeDuplicates()
            .sink { [weak self] newSelectionType in
                guard let self else { return }
                self.timeRangeGenerator = AnalyticsHubTimeRangeGenerator(selectionType: newSelectionType)
                self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeGenerator: self.timeRangeGenerator)
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

    static func productCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsProductCardViewModel {
        let showSyncError = currentPeriodStats == nil || previousPeriodStats == nil
        let itemsSold = StatsDataTextFormatter.createItemsSoldText(orderStats: currentPeriodStats)
        let itemsSoldDelta = StatsDataTextFormatter.createOrderItemsSoldDelta(from: previousPeriodStats, to: currentPeriodStats)

        let imageURL = URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
        return AnalyticsProductCardViewModel(itemsSold: itemsSold,
                                             delta: itemsSoldDelta.string,
                                             deltaBackgroundColor: Constants.deltaColor(for: itemsSoldDelta.direction),
                                             itemsSoldData: [ // Temporary data
                                                .init(imageURL: imageURL, name: "Tabletop Photos", details: "Net Sales: $1,232", value: "32"),
                                                .init(imageURL: imageURL, name: "Kentya Palm", details: "Net Sales: $800", value: "10"),
                                                .init(imageURL: imageURL, name: "Love Ficus", details: "Net Sales: $599", value: "5"),
                                                .init(imageURL: imageURL, name: "Bird Of Paradise", details: "Net Sales: $23.50", value: "2")
                                             ],
                                             isRedacted: false,
                                             showSyncError: showSyncError)
    }

    static func timeRangeCard(timeRangeGenerator: AnalyticsHubTimeRangeGenerator) -> AnalyticsTimeRangeCardViewModel {
        return AnalyticsTimeRangeCardViewModel(selectedRangeTitle: timeRangeGenerator.selectionDescription,
                                               currentRangeSubtitle: timeRangeGenerator.generateCurrentRangeDescription(),
                                               previousRangeSubtitle: timeRangeGenerator.generatePreviousRangeDescription())
    }
}

// MARK: - Constants
private extension AnalyticsHubViewModel {
    enum Constants {
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
    }
}
