import Foundation
import Yosemite
import Combine
import class UIKit.UIColor

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    private let siteID: Int64
    private let stores: StoresManager
    private let timeZone: TimeZone
    private let analytics: Analytics
    private let noticePresenter: NoticePresenter

    /// Delay to allow the backend to process enabling the Jetpack Stats module.
    /// Defaults to 0.5 seconds.
    private let backendProcessingDelay: UInt64

    private var subscriptions = Set<AnyCancellable>()

    /// Analytics Usage Tracks Event Emitter
    ///
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    /// User is an administrator on the store
    ///
    private let userIsAdmin: Bool

    /// Whether the `customizeAnalyticsHub` feature flag is enabled
    ///
    let canCustomizeAnalytics: Bool

    init(siteID: Int64,
         timeZone: TimeZone = .siteTimezone,
         statsTimeRange: StatsTimeRangeV4,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         backendProcessingDelay: UInt64 = 500_000_000,
         canCustomizeAnalytics: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.customizeAnalyticsHub)) {
        let selectedType = AnalyticsHubTimeRangeSelection.SelectionType(statsTimeRange)
        let timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: selectedType, timezone: timeZone)

        self.siteID = siteID
        self.timeZone = timeZone
        self.stores = stores
        self.userIsAdmin = stores.sessionManager.defaultRoles.contains(.administrator)
        self.analytics = analytics
        self.noticePresenter = noticePresenter
        self.backendProcessingDelay = backendProcessingDelay
        self.timeRangeSelectionType = selectedType
        self.timeRangeSelection = timeRangeSelection
        self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeSelection: timeRangeSelection,
                                                                 usageTracksEventEmitter: usageTracksEventEmitter,
                                                                 analytics: analytics)
        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.canCustomizeAnalytics = canCustomizeAnalytics

        let storeAdminURL = stores.sessionManager.defaultSite?.adminURL
        let revenueWebReportVM = AnalyticsHubViewModel.webReportVM(for: .revenue,
                                                                   timeRange: selectedType,
                                                                   storeAdminURL: storeAdminURL,
                                                                   usageTracksEventEmitter: usageTracksEventEmitter)
        self.revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: nil,
                                                             previousPeriodStats: nil,
                                                             webReportViewModel: revenueWebReportVM)

        let ordersWebReportVM = AnalyticsHubViewModel.webReportVM(for: .orders,
                                                                  timeRange: selectedType,
                                                                  storeAdminURL: storeAdminURL,
                                                                  usageTracksEventEmitter: usageTracksEventEmitter)
        self.ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: nil,
                                                           previousPeriodStats: nil,
                                                           webReportViewModel: ordersWebReportVM)

        let productsWebReportVM = AnalyticsHubViewModel.webReportVM(for: .products,
                                                                    timeRange: selectedType,
                                                                    storeAdminURL: storeAdminURL,
                                                                    usageTracksEventEmitter: usageTracksEventEmitter)
        self.productsStatsCard = AnalyticsHubViewModel.productsStatsCard(currentPeriodStats: nil,
                                                                         previousPeriodStats: nil,
                                                                         webReportViewModel: productsWebReportVM)

        bindViewModelsWithData()
    }

    /// Revenue Card ViewModel
    ///
    @Published var revenueCard: AnalyticsReportCardViewModel

    /// Orders Card ViewModel
    ///
    @Published var ordersCard: AnalyticsReportCardViewModel

    /// Products Stats Card ViewModel
    ///
    @Published var productsStatsCard: AnalyticsProductsStatsCardViewModel

    /// Items Sold Card ViewModel
    ///
    @Published var itemsSoldCard = AnalyticsHubViewModel.productsItemsSoldCard(itemsSoldStats: nil)

    /// Sessions Card ViewModel
    ///
    @Published var sessionsCard = AnalyticsHubViewModel.sessionsCard(currentPeriodStats: nil, siteStats: nil)

    /// View model for `AnalyticsHubCustomizeView`, to customize the cards in the Analytics Hub.
    ///
    @Published var customizeAnalyticsViewModel: AnalyticsHubCustomizeViewModel?

    /// Sessions Card display state
    ///
    var showSessionsCard: Bool {
        if !isCardEnabled(.sessions) {
            return false
        } else if stores.isAuthenticatedWithoutWPCom // Non-Jetpack stores don't have sessions stats
            || (isJetpackStatsDisabled && !userIsAdmin) { // Non-admins can't enable sessions stats
            return false
        } else if case .custom = timeRangeSelectionType {
            return false
        } else {
            return true
        }
    }

    /// Whether Jetpack Stats are disabled on the store
    ///
    private var isJetpackStatsDisabled = false

    /// Whether to show the call to action to enable Jetpack Stats
    ///
    var showJetpackStatsCTA: Bool {
        isJetpackStatsDisabled && userIsAdmin
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

    /// All analytics cards to display in the Analytics Hub.
    ///
    var enabledCards: [AnalyticsCard.CardType] {
        let allCards = canCustomizeAnalytics ? allCardsWithSettings : AnalyticsHubViewModel.defaultCards
        return allCards.filter { $0.enabled }.map { $0.type }
    }

    // MARK: Private data

    /// All analytics cards with their enabled/disabled settings.
    /// Defaults to all enabled cards in default order.
    ///
    @Published private(set) var allCardsWithSettings = AnalyticsHubViewModel.defaultCards

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
            let tracker = WaitingTimeTracker(trackScenario: .analyticsHub, analyticsService: analytics)
            try await retrieveData()
            tracker.end()
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

    /// Enables the Jetpack Status module on the store and requests new stats data
    ///
    @MainActor
    func enableJetpackStats() async {
        analytics.track(event: .AnalyticsHub.jetpackStatsCTATapped())

        do {
            try await remoteEnableJetpackStats()
            // Wait for backend to enable the module (it is not ready for stats to be requested immediately after a success response)
            try await Task.sleep(nanoseconds: backendProcessingDelay)
            await updateData()
        } catch {
            noticePresenter.enqueue(notice: .init(title: Localization.statsCTAError))
            DDLogError("⚠️ Error enabling Jetpack Stats: \(error)")
        }
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
                await self.retrieveOrderStats(currentTimeRange: currentTimeRange, previousTimeRange: previousTimeRange, timeZone: self.timeZone)
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
    func retrieveOrderStats(currentTimeRange: AnalyticsHubTimeRange, previousTimeRange: AnalyticsHubTimeRange, timeZone: TimeZone) async {
        async let currentPeriodRequest = retrieveStats(timeZone: timeZone,
                                                       earliestDateToInclude: currentTimeRange.start,
                                                       latestDateToInclude: currentTimeRange.end,
                                                       forceRefresh: true)
        async let previousPeriodRequest = retrieveStats(timeZone: timeZone,
                                                        earliestDateToInclude: previousTimeRange.start,
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
        isJetpackStatsDisabled = false // Reset optimistically in case stats were enabled
        async let siteStatsRequest = retrieveSiteSummaryStats(latestDateToInclude: currentTimeRange.end)

        do {
            self.siteStats = try await siteStatsRequest
        } catch SiteStatsStoreError.statsModuleDisabled {
            self.isJetpackStatsDisabled = true
            self.siteStats = nil
            if showJetpackStatsCTA {
                analytics.track(event: .AnalyticsHub.jetpackStatsCTAShown())
            }
            DDLogError("⚠️ Analytics Hub Sessions card can't be loaded: Jetpack stats are disabled")
        } catch {
            self.siteStats = nil
            DDLogError("⚠️ Analytics Hub Sessions card can't be loaded: \(error)")
        }
    }

    @MainActor
    func retrieveStats(timeZone: TimeZone,
                       earliestDateToInclude: Date,
                       latestDateToInclude: Date,
                       forceRefresh: Bool) async throws -> OrderStatsV4 {
        try await withCheckedThrowingContinuation { continuation in
            let action = StatsActionV4.retrieveCustomStats(siteID: siteID,
                                                           unit: timeRangeSelectionType.granularity,
                                                           timeZone: timeZone,
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
                                                              timeZone: timeZone,
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
        guard !stores.isAuthenticatedWithoutWPCom, let period = timeRangeSelectionType.period else {
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

    @MainActor
    /// Makes the remote request to enable the Jetpack Stats module on the site.
    ///
    func remoteEnableJetpackStats() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let action = JetpackSettingsAction.enableJetpackModule(.stats, siteID: siteID) { [weak self] result in
                switch result {
                case .success:
                    self?.isJetpackStatsDisabled = false
                    self?.analytics.track(event: .AnalyticsHub.enableJetpackStatsSuccess())
                    continuation.resume()
                case let .failure(error):
                    self?.isJetpackStatsDisabled = true
                    self?.analytics.track(event: .AnalyticsHub.enableJetpackStatsFailed(error: error))
                    continuation.resume(throwing: error)
                }
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

                self.revenueCard = AnalyticsHubViewModel.revenueCard(currentPeriodStats: currentOrderStats,
                                                                     previousPeriodStats: previousOrderStats,
                                                                     webReportViewModel: webReportVM(for: .revenue))
                self.ordersCard = AnalyticsHubViewModel.ordersCard(currentPeriodStats: currentOrderStats,
                                                                   previousPeriodStats: previousOrderStats,
                                                                   webReportViewModel: webReportVM(for: .orders))
                self.productsStatsCard = AnalyticsHubViewModel.productsStatsCard(currentPeriodStats: currentOrderStats,
                                                                                 previousPeriodStats: previousOrderStats,
                                                                                 webReportViewModel: webReportVM(for: .products))

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
                self.timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: newSelectionType, timezone: timeZone)
                self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeSelection: self.timeRangeSelection,
                                                                         usageTracksEventEmitter: self.usageTracksEventEmitter,
                                                                         analytics: self.analytics)

                // Update data on range selection change
                Task.init {
                    await self.updateData()
                }
            }.store(in: &subscriptions)
    }

    static func revenueCard(currentPeriodStats: OrderStatsV4?,
                            previousPeriodStats: OrderStatsV4?,
                            webReportViewModel: AnalyticsReportLinkViewModel?) -> AnalyticsReportCardViewModel {
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
                                            syncErrorMessage: Localization.RevenueCard.noRevenue,
                                            reportViewModel: webReportViewModel)
    }

    static func ordersCard(currentPeriodStats: OrderStatsV4?,
                           previousPeriodStats: OrderStatsV4?,
                           webReportViewModel: AnalyticsReportLinkViewModel?) -> AnalyticsReportCardViewModel {
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
                                            syncErrorMessage: Localization.OrderCard.noOrders,
                                            reportViewModel: webReportViewModel)
    }

    /// Helper function to create a `AnalyticsProductsStatsCardViewModel` from the fetched stats.
    ///
    static func productsStatsCard(currentPeriodStats: OrderStatsV4?,
                                  previousPeriodStats: OrderStatsV4?,
                                  webReportViewModel: AnalyticsReportLinkViewModel?) -> AnalyticsProductsStatsCardViewModel {
        let showStatsError = currentPeriodStats == nil || previousPeriodStats == nil
        let itemsSold = StatsDataTextFormatter.createItemsSoldText(orderStats: currentPeriodStats)
        let itemsSoldDelta = StatsDataTextFormatter.createOrderItemsSoldDelta(from: previousPeriodStats, to: currentPeriodStats)

        return AnalyticsProductsStatsCardViewModel(itemsSold: itemsSold,
                                                   delta: itemsSoldDelta,
                                                   isRedacted: false,
                                                   showStatsError: showStatsError,
                                                   reportViewModel: webReportViewModel)
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

    /// Gets the view model to show a web analytics report, based on the provided report type and currently selected time range
    ///
    func webReportVM(for report: AnalyticsWebReport.ReportType) -> AnalyticsReportLinkViewModel? {
        return AnalyticsHubViewModel.webReportVM(for: report,
                                                 timeRange: timeRangeSelectionType,
                                                 storeAdminURL: stores.sessionManager.defaultSite?.adminURL,
                                                 usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Gets the view model to show a web analytics report, based on the provided report type, time range, and store admin URL
    ///
    static func webReportVM(for report: AnalyticsWebReport.ReportType,
                            timeRange: AnalyticsHubTimeRangeSelection.SelectionType,
                            storeAdminURL: String?,
                            usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) -> AnalyticsReportLinkViewModel? {
        guard let url = AnalyticsWebReport.getUrl(for: report, timeRange: timeRange, storeAdminURL: storeAdminURL) else {
            return nil
        }
        let title = {
            switch report {
            case .revenue:
                return Localization.RevenueCard.reportTitle
            case .orders:
                return Localization.OrderCard.reportTitle
            case .products:
                return Localization.ProductCard.reportTitle
            }
        }()
        return AnalyticsReportLinkViewModel(reportType: report,
                                            period: timeRange,
                                            webViewTitle: title,
                                            reportURL: url,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Whether the card should be displayed in the Analytics Hub.
    ///
    func isCardEnabled(_ type: AnalyticsCard.CardType) -> Bool {
        return enabledCards.contains(where: { $0 == type })
    }
}

// MARK: - Customize analytics cards
extension AnalyticsHubViewModel {
    /// Load analytics card settings from storage
    /// Defaults to all enabled cards in default order if no customized settings are stored.
    ///
    @MainActor
    func loadAnalyticsCardSettings() async {
        allCardsWithSettings = await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadAnalyticsHubCards(siteID: siteID) { cards in
                continuation.resume(returning: cards ?? AnalyticsHubViewModel.defaultCards)
            }
            stores.dispatch(action)
        }
    }

    /// Sets analytics card settings in storage
    ///
    private func storeAnalyticsCardSettings(_ cards: [AnalyticsCard]) {
        let action = AppSettingsAction.setAnalyticsHubCards(siteID: siteID, cards: cards)
        stores.dispatch(action)
    }

    /// Sets a view model for `customizeAnalyticsViewModel` when the feature is enabled.
    /// This allows the view to open
    ///
    func customizeAnalytics() {
        guard canCustomizeAnalytics else {
            return
        }

        customizeAnalyticsViewModel = AnalyticsHubCustomizeViewModel(allCards: allCardsWithSettings) { [weak self] updatedCards in
            guard let self else { return }
            self.allCardsWithSettings = updatedCards
            self.storeAnalyticsCardSettings(updatedCards)
        }
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
            static let reportTitle = NSLocalizedString("analyticsHub.revenueCard.reportTitle",
                                                       value: "Revenue Report",
                                                       comment: "Title for the revenue analytics report linked in the Analytics Hub")
        }

        enum OrderCard {
            static let title = NSLocalizedString("ORDERS", comment: "Title for order analytics section in the Analytics Hub")
            static let leadingTitle = NSLocalizedString("Total Orders", comment: "Label for total number of orders in the Analytics Hub")
            static let trailingTitle = NSLocalizedString("Average Order Value", comment: "Label for average value of orders in the Analytics Hub")
            static let noOrders = NSLocalizedString("Unable to load order analytics",
                                                    comment: "Text displayed when there is an error loading order stats data.")
            static let reportTitle = NSLocalizedString("analyticsHub.orderCard.reportTitle",
                                                       value: "Orders Report",
                                                       comment: "Title for the orders analytics report linked in the Analytics Hub")
        }

        enum ProductCard {
            static func netSales(value: String) -> String {
                String.localizedStringWithFormat(NSLocalizedString("Net sales: %@", comment: "Label for the total sales of a product in the Analytics Hub"),
                                                 value)
            }
            static let reportTitle = NSLocalizedString("analyticsHub.productCard.reportTitle",
                                                       value: "Products Report",
                                                       comment: "Title for the products analytics report linked in the Analytics Hub")
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
        static let statsCTAError = NSLocalizedString("analyticsHub.jetpackStatsCTA.errorNotice",
                                                     value: "We couldn't enable Jetpack Stats on your store",
                                                     comment: "Error shown when Jetpack Stats can't be enabled in the Analytics Hub.")
    }

    /// Set of enabled analytics cards in default order.
    static let defaultCards: [AnalyticsCard] = AnalyticsCard.CardType.allCases.map { type in
        AnalyticsCard(type: type, enabled: true)
    }
}
