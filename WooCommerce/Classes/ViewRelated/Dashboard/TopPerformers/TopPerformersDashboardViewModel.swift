import WooFoundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `TopPerformersDashboardView`
///
final class TopPerformersDashboardViewModel: ObservableObject {

    @Published private(set) var timeRange = StatsTimeRangeV4.today
    @Published private(set) var syncingData = false
    @Published var selectedItem: TopEarnerStatsItem?

    let siteID: Int64
    let siteTimezone: TimeZone
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter
    private let currencySettings: CurrencySettings
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter
    private let analytics: Analytics

    private var resultsController: ResultsController<StorageTopEarnerStats>?

    private var currentDate: Date {
        Date()
    }

    lazy var dataViewModel = DashboardTopPerformersViewModel(state: .loading) { [weak self] topPerformersItem in
        guard let self else { return }
        usageTracksEventEmitter.interacted()
        selectedItem = topPerformersItem
    }

    private var topEarnerStats: TopEarnerStats? {
        resultsController?.fetchedObjects.first
    }

    init(siteID: Int64,
         siteTimezone: TimeZone = .siteTimezone,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.siteTimezone = siteTimezone
        self.storageManager = storageManager
        self.currencyFormatter = currencyFormatter
        self.currencySettings = currencySettings
        self.analytics = analytics
        self.usageTracksEventEmitter = usageTracksEventEmitter

        Task { @MainActor in
            self.timeRange = await loadLastTimeRange() ?? .today
            updateResultsController()
            await reloadData()
        }
    }

    func didSelectTimeRange(_ newTimeRange: StatsTimeRangeV4) {
        timeRange = newTimeRange
        saveLastTimeRange(timeRange)
        usageTracksEventEmitter.interacted()
        analytics.track(event: .Dashboard.dashboardMainStatsDate(timeRange: timeRange))
        updateResultsController()

        Task { [weak self] in
            await self?.reloadData()
        }
    }

    @MainActor
    func reloadData() async {
        syncingData = true
        updateUIInLoadingState()
        do {
            try await syncTopEarnersStats()
            ServiceLocator.analytics.track(event:
                    .Dashboard.dashboardTopPerformersLoaded(timeRange: timeRange))
        } catch {
            DDLogError("⛔️ Dashboard (Top Performers) — Error synchronizing top earner stats: \(error)")
        }
        syncingData = false
        updateUIInLoadedState()
    }
}

// MARK: - Data for `TopPerformersDashboardView`
//
extension TopPerformersDashboardViewModel {
    var timeRangeText: String {
        guard let timeRangeViewModel = StatsTimeRangeBarViewModel(timeRange: timeRange, timezone: siteTimezone) else {
            return ""
        }
        return timeRangeViewModel.timeRangeText
    }

    var startDateForCustomRange: Date {
        if case let .custom(startDate, _) = timeRange {
            return startDate
        }
        return Date(timeInterval: -Constants.thirtyDaysInSeconds, since: endDateForCustomRange) // 30 days before end date
    }

    var endDateForCustomRange: Date {
        if case let .custom(_, endDate) = timeRange {
            return endDate
        }
        return Date()
    }

    var buttonTitleForCustomRange: String? {
        if case .custom = timeRange {
            return nil
        }
        return Localization.addCustomRange
    }
}

// MARK: - Private helpers
//
private extension TopPerformersDashboardViewModel {

    @MainActor
    func loadLastTimeRange() async -> StatsTimeRangeV4? {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadLastSelectedStatsTimeRange(siteID: siteID) { timeRange in
                continuation.resume(returning: timeRange)
            }
            stores.dispatch(action)
        }
    }

    func saveLastTimeRange(_ timeRange: StatsTimeRangeV4) {
        let action = AppSettingsAction.setLastSelectedStatsTimeRange(siteID: siteID, timeRange: timeRange)
        stores.dispatch(action)
    }

    func updateResultsController() {
        let resultsController = createResultsController(timeRange: timeRange)
        self.resultsController = resultsController
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateUIInLoadedState()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateUIInLoadedState()
        }

        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func updateUIInLoadingState() {
        dataViewModel.update(state: .loading)
    }

    func updateUIInLoadedState() {
        guard !syncingData else {
            return
        }
        guard let items = topEarnerStats?.items?.sorted(by: >), items.isNotEmpty else {
            return dataViewModel.update(state: .loaded(rows: []))
        }
        dataViewModel.update(state: .loaded(rows: items))
    }

    func createResultsController(timeRange: StatsTimeRangeV4) -> ResultsController<StorageTopEarnerStats> {
        let granularity = timeRange.topEarnerStatsGranularity
        let formattedDateString: String = {
            let date = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimezone)
            return StatsStoreV4.buildDateString(from: date, with: granularity)
        }()
        let predicate = NSPredicate(format: "granularity = %@ AND date = %@ AND siteID = %ld", granularity.rawValue, formattedDateString, siteID)
        let descriptor = NSSortDescriptor(key: "date", ascending: true)

        return ResultsController<StorageTopEarnerStats>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }

    @MainActor
    func syncTopEarnersStats() async throws {
        let latestDateToInclude = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimezone)
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        try await withCheckedThrowingContinuation { continuation in
            let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardTopPerformers)
            stores.dispatch(StatsActionV4.retrieveTopEarnerStats(siteID: siteID,
                                                                 timeRange: timeRange,
                                                                 timeZone: siteTimezone,
                                                                 earliestDateToInclude: earliestDateToInclude,
                                                                 latestDateToInclude: latestDateToInclude,
                                                                 quantity: Constants.topEarnerStatsLimit,
                                                                 forceRefresh: true,
                                                                 saveInStorage: true,
                                                                 onCompletion: { result in
                waitingTracker.end()
                let voidResult = result.map { _ in () } // Caller expects no entity in the result.
                continuation.resume(with: voidResult)
            }))
        }
    }
}

// MARK: Constants
//
private extension TopPerformersDashboardViewModel {
    enum Constants {
        static let thirtyDaysInSeconds: TimeInterval = 86400*30
        static let topEarnerStatsLimit: Int = 5
    }
    enum Localization {
        static let addCustomRange = NSLocalizedString(
            "topPerformerDashboardViewModel.addCustomRange",
            value: "Add",
            comment: "Button in date range picker to add a Custom Range tab"
        )
    }
}
