import Foundation
import Yosemite
import Combine
import class UIKit.UIColor

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    private var subscriptions = Set<AnyCancellable>()

    /// Analytics Usage Tracks Event Emitter
    ///
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    init(siteID: Int64,
         statsTimeRange: StatsTimeRangeV4,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        let selectedType = AnalyticsHubTimeRangeSelection.SelectionType(statsTimeRange)
        let timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: selectedType)

        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.timeRangeSelectionType = selectedType
        self.timeRangeSelection = timeRangeSelection
        self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeSelection: timeRangeSelection,
                                                                 usageTracksEventEmitter: usageTracksEventEmitter,
                                                                 analytics: analytics)
        self.usageTracksEventEmitter = usageTracksEventEmitter

        bindViewModelsWithData()
    }

    /// Revenue Card ViewModel
    ///
    @Published var revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: nil, previousPeriodStats: nil)

    /// Orders Card ViewModel
    ///
    @Published var ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: nil, previousPeriodStats: nil)

    /// Products Stats Card ViewModel
    ///
    @Published var productsStatsCard = AnalyticsHubViewModel.productsStatsCard(currentPeriodStats: nil, previousPeriodStats: nil)

    /// Items Sold Card ViewModel
    ///
    @Published var itemsSoldCard = AnalyticsHubViewModel.productsItemsSoldCard(itemsSoldStats: nil)

    /// Sessions Card ViewModel
    ///
    @Published var sessionsCard = AnalyticsHubViewModel.sessionsCard(currentPeriodStats: nil, siteStats: nil)

    /// Sessions Card display state
    ///
    var showSessionsCard: Bool {
        switch timeRangeSelectionType {
        case .custom:
            return false
        default:
            return true
        }
    }

    /// Time Range Selection Type
    ///
    @Published var timeRangeSelectionType: AnalyticsHubTimeRangeSelection.SelectionType

    /// Time Range ViewModel
    ///
    @Published var timeRangeCard: AnalyticsTimeRangeCardViewModel

    /// Defines a notice that, when set, dismisses the view and is then displayed.
    /// Defaults to `nil`.
    ///
    @Published var dismissNotice: Notice?

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

    /// Site summary stats for visitors and views. Used in the sessions card.
    ///
    @Published private var siteStats: SiteSummaryStats? = nil

    /// Time Range selection data defining the current and previous time period
    ///
    private var timeRangeSelection: AnalyticsHubTimeRangeSelection

    /// Request stats data from network
    ///
    @MainActor
    func updateData() async {
        do {
            try await retrieveData()
        } catch is AnalyticsHubTimeRangeSelection.TimeRangeGeneratorError {
            dismissNotice = Notice(title: Localization.timeRangeGeneratorError, feedbackType: .error)
            ServiceLocator.analytics.track(event: .AnalyticsHub.dateRangeSelectionFailed(for: timeRangeSelectionType))
            DDLogWarn("⚠️ Error selecting analytics time range: \(timeRangeSelectionType.description)")
        } catch {
            switchToErrorState()
            DDLogWarn("⚠️ Error fetching analytics data: \(error)")
        }
    }

    /// Tracks interactions for analytics usage event
    ///
    func trackAnalyticsInteraction() {
        usageTracksEventEmitter.interacted()
    }
}

// MARK: Networking
private extension AnalyticsHubViewModel {

    @MainActor
    func retrieveData() async throws {
        switchToLoadingState()

        let currentTimeRange = try timeRangeSelection.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRangeSelection.unwrapPreviousTimeRange()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.retrieveOrderStats(currentTimeRange: currentTimeRange, previousTimeRange: previousTimeRange)
            }
            group.addTask {
                await self.retrieveItemsSoldStats(currentTimeRange: currentTimeRange, previousTimeRange: previousTimeRange)
            }
            group.addTask {
                await self.retrieveSiteStats(currentTimeRange: currentTimeRange)
            }
        }
    }

    @MainActor
    func retrieveOrderStats(currentTimeRange: AnalyticsHubTimeRange, previousTimeRange: AnalyticsHubTimeRange) async {
        async let currentPeriodRequest = retrieveStats(earliestDateToInclude: currentTimeRange.start,
                                                       latestDateToInclude: currentTimeRange.end,
                                                       forceRefresh: true)
        async let previousPeriodRequest = retrieveStats(earliestDateToInclude: previousTimeRange.start,
                                                        latestDateToInclude: previousTimeRange.end,
                                                        forceRefresh: true)

        let allStats: (currentPeriodStats: OrderStatsV4, previousPeriodStats: OrderStatsV4)?
        allStats = try? await (currentPeriodRequest, previousPeriodRequest)
        self.currentOrderStats = allStats?.currentPeriodStats
        self.previousOrderStats = allStats?.previousPeriodStats
    }

    @MainActor
    func retrieveItemsSoldStats(currentTimeRange: AnalyticsHubTimeRange, previousTimeRange: AnalyticsHubTimeRange) async {
        async let itemsSoldRequest = retrieveTopItemsSoldStats(earliestDateToInclude: currentTimeRange.start,
                                                               latestDateToInclude: currentTimeRange.end,
                                                               forceRefresh: true)

        self.itemsSoldStats = try? await itemsSoldRequest
    }

    @MainActor
    func retrieveSiteStats(currentTimeRange: AnalyticsHubTimeRange) async {
        async let siteStatsRequest = retrieveSiteSummaryStats(latestDateToInclude: currentTimeRange.end)

        self.siteStats = try? await siteStatsRequest
    }

    @MainActor
    func retrieveStats(earliestDateToInclude: Date,
                       latestDateToInclude: Date,
                       forceRefresh: Bool) async throws -> OrderStatsV4 {
        try await withCheckedThrowingContinuation { continuation in
            let action = StatsActionV4.retrieveCustomStats(siteID: siteID,
                                                           unit: timeRangeSelectionType.granularity,
                                                           earliestDateToInclude: earliestDateToInclude,
                                                           latestDateToInclude: latestDateToInclude,
                                                           quantity: timeRangeSelectionType.intervalSize,
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

    @MainActor
    /// Retrieves site summary stats using the `retrieveSiteSummaryStats` action.
    ///
    func retrieveSiteSummaryStats(latestDateToInclude: Date) async throws -> SiteSummaryStats? {
        guard let period = timeRangeSelectionType.period else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let action = StatsActionV4.retrieveSiteSummaryStats(siteID: siteID,
                                                                siteTimezone: .current,
                                                                period: period,
                                                                quantity: timeRangeSelectionType.quantity,
                                                                latestDateToInclude: latestDateToInclude,
                                                                saveInStorage: false) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }
}

// MARK: Data - UI mapping
private extension AnalyticsHubViewModel {

    @MainActor
    func switchToLoadingState() {
        self.revenueCard = revenueCard.redacted
        self.ordersCard = ordersCard.redacted
        self.productsStatsCard = productsStatsCard.redacted
        self.itemsSoldCard = itemsSoldCard.redacted
        self.sessionsCard = sessionsCard.redacted
    }

    @MainActor
    func switchToErrorState() {
        self.currentOrderStats = nil
        self.previousOrderStats = nil
        self.itemsSoldStats = nil
        self.siteStats = nil
    }

    func bindViewModelsWithData() {
        Publishers.CombineLatest($currentOrderStats, $previousOrderStats)
            .sink { [weak self] currentOrderStats, previousOrderStats in
                guard let self else { return }

                self.revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.productsStatsCard = AnalyticsHubViewModel.productsStatsCard(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)

            }.store(in: &subscriptions)

        $itemsSoldStats
            .sink { [weak self] itemsSoldStats in
                guard let self else { return }

                self.itemsSoldCard = AnalyticsHubViewModel.productsItemsSoldCard(itemsSoldStats: itemsSoldStats)
            }.store(in: &subscriptions)

        $currentOrderStats.zip($siteStats)
            .sink { [weak self] (currentOrderStats, siteStats) in
                guard let self else { return }

                self.sessionsCard = AnalyticsHubViewModel.sessionsCard(currentPeriodStats: currentOrderStats, siteStats: siteStats)
            }.store(in: &subscriptions)

        $timeRangeSelectionType
            .dropFirst() // do not trigger refresh action on initial value
            .removeDuplicates()
            .sink { [weak self] newSelectionType in
                guard let self else { return }
                self.timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: newSelectionType)
                self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeSelection: self.timeRangeSelection,
                                                                         usageTracksEventEmitter: self.usageTracksEventEmitter,
                                                                         analytics: self.analytics)

                // Update data on range selection change
                Task.init {
                    await self.updateData()
                }
            }.store(in: &subscriptions)
    }

    static func revenueCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardViewModel {
        let showSyncError = currentPeriodStats == nil || previousPeriodStats == nil

        return AnalyticsReportCardViewModel(title: Localization.RevenueCard.title,
                                            leadingTitle: Localization.RevenueCard.leadingTitle,
                                            leadingValue: StatsDataTextFormatter.createTotalRevenueText(orderStats: currentPeriodStats,
                                                                                                        selectedIntervalIndex: nil),
                                            leadingDelta: StatsDataTextFormatter.createTotalRevenueDelta(from: previousPeriodStats, to: currentPeriodStats),
                                            leadingChartData: StatsIntervalDataParser.getChartData(for: .totalRevenue, from: currentPeriodStats),
                                            trailingTitle: Localization.RevenueCard.trailingTitle,
                                            trailingValue: StatsDataTextFormatter.createNetRevenueText(orderStats: currentPeriodStats),
                                            trailingDelta: StatsDataTextFormatter.createNetRevenueDelta(from: previousPeriodStats, to: currentPeriodStats),
                                            trailingChartData: StatsIntervalDataParser.getChartData(for: .netRevenue, from: currentPeriodStats),
                                            isRedacted: false,
                                            showSyncError: showSyncError,
                                            syncErrorMessage: Localization.RevenueCard.noRevenue)
    }

    static func ordersCard(currentPeriodStats: OrderStatsV4?, previousPeriodStats: OrderStatsV4?) -> AnalyticsReportCardViewModel {
        let showSyncError = currentPeriodStats == nil || previousPeriodStats == nil

        return AnalyticsReportCardViewModel(title: Localization.OrderCard.title,
                                            leadingTitle: Localization.OrderCard.leadingTitle,
                                            leadingValue: StatsDataTextFormatter.createOrderCountText(orderStats: currentPeriodStats,
                                                                                                      selectedIntervalIndex: nil),
                                            leadingDelta: StatsDataTextFormatter.createOrderCountDelta(from: previousPeriodStats, to: currentPeriodStats),
                                            leadingChartData: StatsIntervalDataParser.getChartData(for: .orderCount, from: currentPeriodStats),
                                            trailingTitle: Localization.OrderCard.trailingTitle,
                                            trailingValue: StatsDataTextFormatter.createAverageOrderValueText(orderStats: currentPeriodStats),
                                            trailingDelta: StatsDataTextFormatter.createAverageOrderValueDelta(from: previousPeriodStats,
                                                                                                               to: currentPeriodStats),
                                            trailingChartData: StatsIntervalDataParser.getChartData(for: .averageOrderValue, from: currentPeriodStats),
                                            isRedacted: false,
                                            showSyncError: showSyncError,
                                            syncErrorMessage: Localization.OrderCard.noOrders)
    }

    /// Helper function to create a `AnalyticsProductsStatsCardViewModel` from the fetched stats.
    ///
    static func productsStatsCard(currentPeriodStats: OrderStatsV4?,
                                  previousPeriodStats: OrderStatsV4?) -> AnalyticsProductsStatsCardViewModel {
        let showStatsError = currentPeriodStats == nil || previousPeriodStats == nil
        let itemsSold = StatsDataTextFormatter.createItemsSoldText(orderStats: currentPeriodStats)
        let itemsSoldDelta = StatsDataTextFormatter.createOrderItemsSoldDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsProductsStatsCardViewModel(itemsSold: itemsSold,
                                                   delta: itemsSoldDelta,
                                                   isRedacted: false,
                                                   showStatsError: showStatsError)
    }

    /// Helper function to create a `AnalyticsItemsSoldViewModel` from the fetched stats.
    ///
    static func productsItemsSoldCard(itemsSoldStats: TopEarnerStats?) -> AnalyticsItemsSoldViewModel {
        let showItemsSoldError = itemsSoldStats == nil

        return AnalyticsItemsSoldViewModel(itemsSoldData: itemSoldRows(from: itemsSoldStats), isRedacted: false, showItemsSoldError: showItemsSoldError)
    }

    /// Helper function to create a `AnalyticsReportCardCurrentPeriodViewModel` from the fetched stats.
    ///
    static func sessionsCard(currentPeriodStats: OrderStatsV4?, siteStats: SiteSummaryStats?) -> AnalyticsReportCardCurrentPeriodViewModel {
        let showSyncError = currentPeriodStats == nil || siteStats == nil

        return AnalyticsReportCardCurrentPeriodViewModel(title: Localization.SessionsCard.title,
                                                         leadingTitle: Localization.SessionsCard.leadingTitle,
                                                         leadingValue: StatsDataTextFormatter.createViewsCountText(siteStats: siteStats),
                                                         trailingTitle: Localization.SessionsCard.trailingTitle,
                                                         trailingValue: StatsDataTextFormatter.createConversionRateText(orderStats: currentPeriodStats,
                                                                                                                        siteStats: siteStats),
                                                         isRedacted: false,
                                                         showSyncError: showSyncError,
                                                         syncErrorMessage: Localization.SessionsCard.noSessions)
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

    static func timeRangeCard(timeRangeSelection: AnalyticsHubTimeRangeSelection,
                              usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
                              analytics: Analytics) -> AnalyticsTimeRangeCardViewModel {
        return AnalyticsTimeRangeCardViewModel(selectedRangeTitle: timeRangeSelection.rangeSelectionDescription,
                                               currentRangeSubtitle: timeRangeSelection.currentRangeDescription,
                                               previousRangeSubtitle: timeRangeSelection.previousRangeDescription,
                                               onTapped: {
            usageTracksEventEmitter.interacted()
            analytics.track(event: .AnalyticsHub.dateRangeButtonTapped())
        },
                                               onSelected: { selection in
            usageTracksEventEmitter.interacted()
            analytics.track(event: .AnalyticsHub.dateRangeOptionSelected(selection.tracksIdentifier))
        })
    }
}

// MARK: - Constants
private extension AnalyticsHubViewModel {
    enum Constants {
        static let maxNumberOfTopItemsSold = 5
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

        enum SessionsCard {
            static let title = NSLocalizedString("SESSIONS", comment: "Title for sessions section in the Analytics Hub")
            static let leadingTitle = NSLocalizedString("Views", comment: "Label for total store views in the Analytics Hub")
            static let trailingTitle = NSLocalizedString("Conversion Rate", comment: "Label for the conversion rate (orders per visitor) in the Analytics Hub")
            static let noSessions = NSLocalizedString("Unable to load session analytics",
                                                      comment: "Text displayed when there is an error loading session stats data.")
        }

        static let timeRangeGeneratorError = NSLocalizedString("Sorry, something went wrong. We can't load analytics for the selected date range.",
                                                               comment: "Error shown when there is a problem retrieving the dates for the selected date range.")
    }
}
