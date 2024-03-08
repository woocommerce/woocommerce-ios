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

    init(siteID: Int64,
         timeZone: TimeZone = .siteTimezone,
         statsTimeRange: StatsTimeRangeV4,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         backendProcessingDelay: UInt64 = 500_000_000) {
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

        let storeAdminURL = stores.sessionManager.defaultSite?.adminURL
        let productsWebReportVM = AnalyticsHubViewModel.webReportVM(for: .products,
                                                                    timeRange: selectedType,
                                                                    storeAdminURL: storeAdminURL,
                                                                    usageTracksEventEmitter: usageTracksEventEmitter)
        self.productsStatsCard = AnalyticsHubViewModel.productsStatsCard(currentPeriodStats: nil,
                                                                         previousPeriodStats: nil,
                                                                         webReportViewModel: productsWebReportVM)

        bindViewModelsWithData()
        bindCardSettingsWithData()
    }

    // MARK: View Models

    /// Revenue Card ViewModel
    ///
    lazy var revenueCard: RevenueReportCardViewModel = {
        RevenueReportCardViewModel(currentPeriodStats: currentOrderStats,
                                   previousPeriodStats: previousOrderStats,
                                   timeRange: timeRangeSelectionType,
                                   usageTracksEventEmitter: usageTracksEventEmitter)
    }()

    /// Orders Card ViewModel
    ///
    lazy var ordersCard: OrdersReportCardViewModel = {
        OrdersReportCardViewModel(currentPeriodStats: currentOrderStats,
                                  previousPeriodStats: previousOrderStats,
                                  timeRange: timeRangeSelectionType,
                                  usageTracksEventEmitter: usageTracksEventEmitter)
    }()

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
        return allCardsWithSettings.filter { card in
            let canBeDisplayed = card.type == .sessions ? showSessionsCard : true
            return card.enabled && canBeDisplayed
        }.map { $0.type }
    }

    /// Sessions Card display state
    ///
    private var showSessionsCard: Bool {
        guard isEligibleForSessionsCard else {
            return false
        }
        if case .custom = timeRangeSelectionType {
            return false
        } else {
            return true
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

    /// Whether to show the call to action to enable Jetpack Stats
    ///
    var showJetpackStatsCTA: Bool {
        isJetpackStatsDisabled && userIsAdmin
    }

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

    /// Time Range selection data defining the current and previous time period
    ///
    private var timeRangeSelection: AnalyticsHubTimeRangeSelection

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

    /// Enables the Jetpack Status module on the store and requests new stats data
    ///
    @MainActor
    func enableJetpackStats() async {
        analytics.track(event: .AnalyticsHub.jetpackStatsCTATapped())

        do {
            try await remoteEnableJetpackStats()
            // Wait for backend to enable the module (it is not ready for stats to be requested immediately after a success response)
            try await Task.sleep(nanoseconds: backendProcessingDelay)
            await updateData(for: [.sessions])
        } catch {
            noticePresenter.enqueue(notice: .init(title: Localization.statsCTAError))
            DDLogError("⚠️ Error enabling Jetpack Stats: \(error)")
        }
    }
}

// MARK: Networking
private extension AnalyticsHubViewModel {

    @MainActor
    func retrieveData(for cards: [AnalyticsCard.CardType]) async throws {
        switchToLoadingState(cards)

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
    func switchToLoadingState(_ cards: [AnalyticsCard.CardType]) {
        cards.forEach { card in
            switch card {
            case .revenue:
                self.revenueCard.redact()
            case .orders:
                self.ordersCard.redact()
            case .products:
                self.productsStatsCard = productsStatsCard.redacted
                self.itemsSoldCard = itemsSoldCard.redacted
            case .sessions:
                self.sessionsCard = sessionsCard.redacted
            }
        }
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

                self.revenueCard.update(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
                self.ordersCard.update(currentPeriodStats: currentOrderStats, previousPeriodStats: previousOrderStats)
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

                self.revenueCard.update(timeRange: newSelectionType)
                self.ordersCard.update(timeRange: newSelectionType)

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
                return ""
            case .orders:
                return ""
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
    /// Setting this view model opens the view.
    ///
    func customizeAnalytics() {
        // Exclude any cards the merchant/store is ineligible for.
        let cardsToExclude: [AnalyticsCard] = [
            isEligibleForSessionsCard ? nil : allCardsWithSettings.first(where: { $0.type == .sessions })
        ].compactMap({ $0 })

        analytics.track(event: .AnalyticsHub.customizeAnalyticsOpened())
        customizeAnalyticsViewModel = AnalyticsHubCustomizeViewModel(allCards: allCardsWithSettings,
                                                                     cardsToExclude: cardsToExclude) { [weak self] updatedCards in
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
