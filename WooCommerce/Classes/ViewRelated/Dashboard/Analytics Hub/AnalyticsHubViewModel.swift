import Foundation
import Yosemite
import Combine
import class UIKit.UIColor
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// Main View Model for the Analytics Hub.
///
final class AnalyticsHubViewModel: ObservableObject {

    let siteID: Int64
    let stores: StoresManager
    private let storage: StorageManagerType
    private let timeZone: TimeZone
    let analytics: Analytics

    private var subscriptions = Set<AnyCancellable>()

    /// Analytics Usage Tracks Event Emitter
    ///
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    /// User is an administrator on the store
    ///
    private let userIsAdmin: Bool

    init(siteID: Int64,
         timeZone: TimeZone = .siteTimezone,
         statsTimeRange: StatsTimeRangeV4,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         stores: StoresManager = ServiceLocator.stores,
         storage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        let selectedType = AnalyticsHubTimeRangeSelection.SelectionType(statsTimeRange)
        let timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: selectedType, timezone: timeZone)

        self.siteID = siteID
        self.timeZone = timeZone
        self.stores = stores
        self.storage = storage
        self.userIsAdmin = stores.sessionManager.defaultRoles.contains(.administrator)
        self.analytics = analytics
        self.timeRangeSelectionType = selectedType
        self.timeRangeSelection = timeRangeSelection
        self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeSelection: timeRangeSelection,
                                                                 usageTracksEventEmitter: usageTracksEventEmitter,
                                                                 analytics: analytics)
        self.usageTracksEventEmitter = usageTracksEventEmitter

        self.googleCampaignsCard = GoogleAdsCampaignReportCardViewModel(siteID: siteID,
                                                                        timeRange: selectedType,
                                                                        usageTracksEventEmitter: usageTracksEventEmitter)

        bindViewModelsWithData()
        bindCardSettingsWithData()
    }

    // MARK: View Models

    /// Revenue Card ViewModel
    ///
    var revenueCard: RevenueReportCardViewModel {
        RevenueReportCardViewModel(currentPeriodStats: currentOrderStats,
                                   previousPeriodStats: previousOrderStats,
                                   timeRange: timeRangeSelectionType,
                                   isRedacted: isLoadingOrderStats,
                                   usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Orders Card ViewModel
    ///
    var ordersCard: OrdersReportCardViewModel {
        OrdersReportCardViewModel(currentPeriodStats: currentOrderStats,
                                  previousPeriodStats: previousOrderStats,
                                  timeRange: timeRangeSelectionType,
                                  isRedacted: isLoadingOrderStats,
                                  usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Products Stats Card ViewModel
    ///
    var productsStatsCard: AnalyticsProductsStatsCardViewModel {
        AnalyticsProductsStatsCardViewModel(currentPeriodStats: currentOrderStats,
                                            previousPeriodStats: previousOrderStats,
                                            timeRange: timeRangeSelectionType,
                                            isRedacted: isLoadingOrderStats,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Items Sold Card ViewModel
    ///
    var itemsSoldCard: AnalyticsItemsSoldViewModel {
        AnalyticsItemsSoldViewModel(itemsSoldStats: itemsSoldStats,
                                    isRedacted: isLoadingItemsSoldStats)
    }

    /// Sessions Card ViewModel
    ///
    var sessionsCard: SessionsReportCardViewModel {
        SessionsReportCardViewModel(siteID: siteID,
                                    currentOrderStats: currentOrderStats,
                                    siteStats: siteStats,
                                    timeRange: timeRangeSelectionType,
                                    isJetpackStatsDisabled: isJetpackStatsDisabled,
                                    isRedacted: isLoadingOrderStats || isLoadingSiteStats,
                                    updateSiteStatsData: { [weak self] in
            await self?.updateData(for: [.sessions])
        })
    }

    /// Product Bundles Card ViewModel
    ///
    var bundlesCard: AnalyticsBundlesReportCardViewModel {
        AnalyticsBundlesReportCardViewModel(currentPeriodStats: currentBundleStats,
                                            previousPeriodStats: previousBundleStats,
                                            bundlesSoldReport: bundlesSoldStats,
                                            timeRange: timeRangeSelectionType,
                                            isRedacted: isLoadingBundleStats,
                                            usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Gift Cards Card ViewModel
    ///
    var giftCardsCard: GiftCardsReportCardViewModel {
        GiftCardsReportCardViewModel(currentPeriodStats: currentGiftCardStats,
                                     previousPeriodStats: previousGiftCardStats,
                                     timeRange: timeRangeSelectionType,
                                     isRedacted: isLoadingGiftCardStats,
                                     usageTracksEventEmitter: usageTracksEventEmitter)
    }

    /// Google Campaigns Card ViewModel
    ///
    var googleCampaignsCard: GoogleAdsCampaignReportCardViewModel

    /// View model for `AnalyticsHubCustomizeView`, to customize the cards in the Analytics Hub.
    ///
    @Published var customizeAnalyticsViewModel: AnalyticsHubCustomizeViewModel?

    /// Time Range Selection Type
    ///
    @Published var timeRangeSelectionType: AnalyticsHubTimeRangeSelection.SelectionType

    /// Time Range ViewModel
    ///
    @Published var timeRangeCard: AnalyticsTimeRangeCardViewModel

    // MARK: Card Display States

    /// All analytics cards to display in the Analytics Hub.
    ///
    var enabledCards: [AnalyticsCard.CardType] {
        return allCardsWithSettings.compactMap { card in
            guard card.enabled, canDisplayCard(ofType: card.type) else {
                return nil
            }
            return card.type
        }
    }

    private func canDisplayCard(ofType card: AnalyticsCard.CardType) -> Bool {
        switch card {
        case .sessions:
            isEligibleForSessionsCard
        case .bundles:
            isPluginActive(SitePlugin.SupportedPlugin.WCProductBundles)
        case .giftCards:
            isPluginActive(SitePlugin.SupportedPlugin.WCGiftCards)
        case .googleCampaigns:
            isPluginActive(SitePlugin.SupportedPlugin.GoogleForWooCommerce) && googleCampaignsCard.isEligibleForGoogleAds
        default:
            true
        }
    }

    /// Whether the user is eligible to view the Sessions cards
    ///
    private var isEligibleForSessionsCard: Bool {
        stores.sessionManager.defaultSite?.isNonJetpackSite == false // Non-Jetpack stores don't have Jetpack stats
        && stores.sessionManager.defaultSite?.isJetpackCPConnected == false // JCP stores don't have Jetpack stats
        && (isJetpackStatsDisabled && !userIsAdmin) == false // Non-admins can't enable sessions stats
    }

    /// Whether Jetpack Stats are disabled on the store
    ///
    private var isJetpackStatsDisabled = false

    /// Defines a notice that, when set, dismisses the view and is then displayed.
    /// Defaults to `nil`.
    ///
    @Published var dismissNotice: Notice?

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

    /// Product bundle stats for the current selected time period. Used in the bundles card.
    ///
    @Published private var currentBundleStats: ProductBundleStats? = nil

    /// Product bundle stats for the previous selected time period. Used in the bundles card.
    ///
    @Published private var previousBundleStats: ProductBundleStats? = nil

    /// Stats fo the current top bundles sold. Used in the bundles card.
    ///
    @Published private var bundlesSoldStats: [ProductsReportItem]? = nil

    /// Gift card stats for the current selected time period. Used in the gift cards card.
    ///
    @Published private var currentGiftCardStats: GiftCardStats? = nil

    /// Gift card stats for the previous selected time period. Used in the gift cards card.
    ///
    @Published private var previousGiftCardStats: GiftCardStats? = nil

    /// Loading state for order stats.
    ///
    @Published private var isLoadingOrderStats = false

    /// Loading state for items sold stats.
    ///
    @Published private var isLoadingItemsSoldStats = false

    /// Loading state for site stats.
    ///
    @Published private var isLoadingSiteStats = false

    /// Loading state for bundle stats.
    ///
    @Published private var isLoadingBundleStats = false

    /// Loading stats for gift card stats.
    ///
    @Published private var isLoadingGiftCardStats = false

    /// Time Range selection data defining the current and previous time period
    ///
    private var timeRangeSelection: AnalyticsHubTimeRangeSelection

    /// Names of the active plugins on the store.
    ///
    private lazy var activePlugins: [String] = {
        let predicate = NSPredicate(format: "siteID == %lld && active == true", siteID)
        let resultsController = ResultsController<StorageSystemPlugin>(storageManager: storage, matching: predicate, sortedBy: [])
        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching active plugins for Analytics Hub")
        }
        return resultsController.fetchedObjects.map { $0.name }
    }()

    /// Request stats data from network
    /// - Parameter cards: Optionally limit the request to only the stats needed for a given set of cards.
    ///
    @MainActor
    func updateData(for cards: [AnalyticsCard.CardType]? = nil) async {
        let cardsNeedingData = cards ?? enabledCards
        do {
            let tracker = WaitingTimeTracker(trackScenario: .analyticsHub, analyticsService: analytics)
            try await retrieveData(for: cardsNeedingData)
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
}

// MARK: Networking
private extension AnalyticsHubViewModel {

    @MainActor
    func retrieveData(for cards: [AnalyticsCard.CardType]) async throws {
        let currentTimeRange = try timeRangeSelection.unwrapCurrentTimeRange()
        let previousTimeRange = try timeRangeSelection.unwrapPreviousTimeRange()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                guard cards.contains(where: [.revenue, .orders, .products, .sessions].contains) else {
                    return
                }
                await self.retrieveOrderStats(currentTimeRange: currentTimeRange, previousTimeRange: previousTimeRange, timeZone: self.timeZone)
            }
            group.addTask {
                guard cards.contains(.products) else {
                    return
                }
                await self.retrieveItemsSoldStats(currentTimeRange: currentTimeRange, previousTimeRange: previousTimeRange)
            }
            group.addTask {
                guard cards.contains(.sessions) else {
                    return
                }
                await self.retrieveSiteStats(currentTimeRange: currentTimeRange)
            }
            group.addTask {
                guard cards.contains(.bundles) else {
                    return
                }
                await self.retrieveBundleStats(currentTimeRange: currentTimeRange, previousTimeRange: previousTimeRange, timeZone: self.timeZone)
            }
            group.addTask {
                guard cards.contains(.giftCards) else {
                    return
                }
                await self.retrieveGiftCardStats(currentTimeRange: currentTimeRange, previousTimeRange: previousTimeRange, timeZone: self.timeZone)
            }
            group.addTask {
                guard cards.contains(.googleCampaigns) else {
                    return
                }
                await self.googleCampaignsCard.reload()
            }
        }
    }

    @MainActor
    func retrieveOrderStats(currentTimeRange: AnalyticsHubTimeRange, previousTimeRange: AnalyticsHubTimeRange, timeZone: TimeZone) async {
        isLoadingOrderStats = true
        defer {
            isLoadingOrderStats = false
        }

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
        isLoadingItemsSoldStats = true
        defer {
            isLoadingItemsSoldStats = false
        }

        async let itemsSoldRequest = retrieveTopItemsSoldStats(earliestDateToInclude: currentTimeRange.start,
                                                               latestDateToInclude: currentTimeRange.end,
                                                               forceRefresh: true)

        self.itemsSoldStats = try? await itemsSoldRequest
    }

    @MainActor
    func retrieveSiteStats(currentTimeRange: AnalyticsHubTimeRange) async {
        isJetpackStatsDisabled = false // Reset optimistically in case stats were enabled
        isLoadingSiteStats = true
        defer {
            isLoadingSiteStats = false
        }

        async let siteStatsRequest = retrieveSiteSummaryStats(latestDateToInclude: currentTimeRange.end)

        do {
            self.siteStats = try await siteStatsRequest
        } catch SiteStatsStoreError.statsModuleDisabled {
            self.isJetpackStatsDisabled = true
            self.siteStats = nil
            DDLogError("⚠️ Analytics Hub Sessions card can't be loaded: Jetpack stats are disabled")
        } catch {
            self.siteStats = nil
            DDLogError("⚠️ Analytics Hub Sessions card can't be loaded: \(error)")
        }
    }

    @MainActor
    func retrieveBundleStats(currentTimeRange: AnalyticsHubTimeRange, previousTimeRange: AnalyticsHubTimeRange, timeZone: TimeZone) async {
        isLoadingBundleStats = true
        defer {
            isLoadingBundleStats = false
        }

        async let currentPeriodRequest = retrieveBundleStats(timeZone: timeZone,
                                                             earliestDateToInclude: currentTimeRange.start,
                                                             latestDateToInclude: currentTimeRange.end,
                                                             forceRefresh: true)
        async let previousPeriodRequest = retrieveBundleStats(timeZone: timeZone,
                                                              earliestDateToInclude: previousTimeRange.start,
                                                              latestDateToInclude: previousTimeRange.end,
                                                              forceRefresh: true)
        async let bundlesSoldRequest = retrieveTopBundlesSoldStats(earliestDateToInclude: currentTimeRange.start,
                                                                   latestDateToInclude: currentTimeRange.end,
                                                                   forceRefresh: true)

        let allStats: (currentPeriodStats: ProductBundleStats, previousPeriodStats: ProductBundleStats, bundlesSold: [ProductsReportItem])?
        allStats = try? await (currentPeriodRequest, previousPeriodRequest, bundlesSoldRequest)
        self.currentBundleStats = allStats?.currentPeriodStats
        self.previousBundleStats = allStats?.previousPeriodStats
        self.bundlesSoldStats = allStats?.bundlesSold
    }

    @MainActor
    func retrieveGiftCardStats(currentTimeRange: AnalyticsHubTimeRange, previousTimeRange: AnalyticsHubTimeRange, timeZone: TimeZone) async {
        isLoadingGiftCardStats = true
        defer {
            isLoadingGiftCardStats = false
        }

        async let currentPeriodRequest = retrieveGiftCardStats(timeZone: timeZone,
                                                               earliestDateToInclude: currentTimeRange.start,
                                                               latestDateToInclude: currentTimeRange.end,
                                                               forceRefresh: true)
        async let previousPeriodRequest = retrieveGiftCardStats(timeZone: timeZone,
                                                                earliestDateToInclude: previousTimeRange.start,
                                                                latestDateToInclude: previousTimeRange.end,
                                                                forceRefresh: true)

        let allStats: (currentPeriodStats: GiftCardStats, previousPeriodStats: GiftCardStats)?
        allStats = try? await (currentPeriodRequest, previousPeriodRequest)
        self.currentGiftCardStats = allStats?.currentPeriodStats
        self.previousGiftCardStats = allStats?.previousPeriodStats
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
    func retrieveTopItemsSoldStats(earliestDateToInclude: Date, latestDateToInclude: Date, forceRefresh: Bool) async throws -> TopEarnerStats? {
        return try await withCheckedThrowingContinuation { continuation in
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

    @MainActor
    /// Retrieves product bundle stats using the `retrieveProductBundleStats` action.
    ///
    func retrieveBundleStats(timeZone: TimeZone,
                             earliestDateToInclude: Date,
                             latestDateToInclude: Date,
                             forceRefresh: Bool) async throws -> ProductBundleStats {
        try await withCheckedThrowingContinuation { continuation in
            let action = StatsActionV4.retrieveProductBundleStats(siteID: siteID,
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
    /// Retrieves top bundles sold stats using the `retrieveTopProductBundles` action.
    ///
    func retrieveTopBundlesSoldStats(earliestDateToInclude: Date, latestDateToInclude: Date, forceRefresh: Bool) async throws -> [ProductsReportItem] {
        return try await withCheckedThrowingContinuation { continuation in
            let action = StatsActionV4.retrieveTopProductBundles(siteID: siteID,
                                                                 timeZone: timeZone,
                                                                 earliestDateToInclude: earliestDateToInclude,
                                                                 latestDateToInclude: latestDateToInclude,
                                                                 quantity: Constants.maxNumberOfTopItemsSold) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    @MainActor
    /// Retrieves gift card stats using the `retrieveUsedGiftCardStats` action.
    ///
    func retrieveGiftCardStats(timeZone: TimeZone,
                               earliestDateToInclude: Date,
                               latestDateToInclude: Date,
                               forceRefresh: Bool) async throws -> GiftCardStats {
        try await withCheckedThrowingContinuation { continuation in
            let action = StatsActionV4.retrieveUsedGiftCardStats(siteID: siteID,
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

    /// Helper function that returns `true` in its callback if the provided plugin name is active on the  store.
    ///
    /// - Parameter plugin: A list of names for the plugin (provide all possible names for plugins that have changed names).
    private func isPluginActive(_ plugin: [String]) -> Bool {
        activePlugins.contains(where: plugin.contains)
    }
}

// MARK: Data - UI mapping
private extension AnalyticsHubViewModel {

    @MainActor
    func switchToErrorState() {
        self.currentOrderStats = nil
        self.previousOrderStats = nil
        self.itemsSoldStats = nil
        self.siteStats = nil
        self.currentBundleStats = nil
        self.previousBundleStats = nil
        self.currentGiftCardStats = nil
        self.previousGiftCardStats = nil
    }

    func bindViewModelsWithData() {
        $timeRangeSelectionType
            .dropFirst() // do not trigger refresh action on initial value
            .removeDuplicates()
            .sink { [weak self] newSelectionType in
                guard let self else { return }
                self.timeRangeSelection = AnalyticsHubTimeRangeSelection(selectionType: newSelectionType, timezone: timeZone)
                self.timeRangeCard = AnalyticsHubViewModel.timeRangeCard(timeRangeSelection: self.timeRangeSelection,
                                                                         usageTracksEventEmitter: self.usageTracksEventEmitter,
                                                                         analytics: self.analytics)

                self.googleCampaignsCard = GoogleAdsCampaignReportCardViewModel(siteID: siteID,
                                                                                timeRange: newSelectionType,
                                                                                usageTracksEventEmitter: usageTracksEventEmitter)

                // Update data on range selection change
                Task.init {
                    await self.updateData()
                }
            }.store(in: &subscriptions)
    }

    func bindCardSettingsWithData() {
        $allCardsWithSettings
            .dropFirst() // do not trigger refresh action on initial value
            .removeDuplicates()
            .sink { [weak self] newCardSettings in
                guard let self else { return }
                // If there are newly enabled cards, fetch their data
                let newlyEnabledCards = newCardSettings.filter({ $0.enabled && !self.enabledCards.contains($0.type) }).map({ $0.type })
                if newlyEnabledCards.isNotEmpty {
                    Task {
                        await self.updateData(for: newlyEnabledCards)
                    }
                }
            }.store(in: &subscriptions)
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

// MARK: - Customize analytics cards
extension AnalyticsHubViewModel {
    /// Load analytics card settings from storage
    /// Defaults to all enabled cards in default order if no customized settings are stored.
    ///
    @MainActor
    func loadAnalyticsCardSettings() async {
        let storedCards = await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadAnalyticsHubCards(siteID: siteID) { cards in
                continuation.resume(returning: cards)
            }
            stores.dispatch(action)
        }

        guard let storedCards else {
            return allCardsWithSettings = AnalyticsHubViewModel.defaultCards
        }

        // Any new cards added to the analytics hub since the stored cards were saved.
        let newCards = AnalyticsHubViewModel.defaultCards.filter { defaultCard in
            !storedCards.contains(where: { $0.type == defaultCard.type })
        }

        allCardsWithSettings = storedCards + newCards
    }

    /// Sets analytics card settings in storage
    ///
    private func storeAnalyticsCardSettings(_ cards: [AnalyticsCard]) {
        let action = AppSettingsAction.setAnalyticsHubCards(siteID: siteID, cards: cards)
        stores.dispatch(action)
    }

    /// Sets a view model for `customizeAnalyticsViewModel` when the feature is enabled.
    /// Setting this view model opens the view.
    ///
    func customizeAnalytics() {
        // Identify any inactive cards (that can't be displayed in the Analytics Hub).
        // Inactive cards are displayed in the customize list with a promo link but can't be customized.
        let inactiveCards: [AnalyticsCard] = allCardsWithSettings.filter { !canDisplayCard(ofType: $0.type) }

        analytics.track(event: .AnalyticsHub.customizeAnalyticsOpened())
        customizeAnalyticsViewModel = AnalyticsHubCustomizeViewModel(allCards: allCardsWithSettings,
                                                                     inactiveCards: inactiveCards) { [weak self] updatedCards in
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
        static let timeRangeGeneratorError = NSLocalizedString("Sorry, something went wrong. We can't load analytics for the selected date range.",
                                                               comment: "Error shown when there is a problem retrieving the dates for the selected date range.")
    }

    /// Set of enabled analytics cards in default order.
    static let defaultCards: [AnalyticsCard] = AnalyticsCard.CardType.allCases.map { type in
        AnalyticsCard(type: type, enabled: true)
    }
}
