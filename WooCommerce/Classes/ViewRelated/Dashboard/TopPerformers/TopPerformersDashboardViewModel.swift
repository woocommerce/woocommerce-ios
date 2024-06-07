import Combine
import WooFoundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `TopPerformersDashboardView`
///
final class TopPerformersDashboardViewModel: ObservableObject {

    // Set externally to trigger callback upon hiding the Top Performers card.
    var onDismiss: (() -> Void)?

    @Published private(set) var timeRange = StatsTimeRangeV4.today
    @Published private(set) var syncingData = false
    @Published var selectedItem: TopEarnerStatsItem?
    @Published private(set) var syncingError: Error?

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

    lazy var periodViewModel = TopPerformersPeriodViewModel(state: .loading) { [weak self] topPerformersItem in
        guard let self else { return }

        trackInteraction()
        selectedItem = topPerformersItem
    }

    private var topEarnerStats: TopEarnerStats? {
        resultsController?.fetchedObjects.first
    }

    private var waitingTracker: WaitingTimeTracker?
    private let syncingDidFinishPublisher = PassthroughSubject<Error?, Never>()
    private var subscriptions = Set<AnyCancellable>()

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

        observeSyncingCompletion()

        Task { @MainActor in
            self.timeRange = await loadLastTimeRange() ?? .today
            updateResultsController()
        }
    }

    func didSelectTimeRange(_ newTimeRange: StatsTimeRangeV4) {
        timeRange = newTimeRange
        saveLastTimeRange(timeRange)
        updateResultsController()

        Task { [weak self] in
            await self?.reloadData()
        }
    }

    @MainActor
    func reloadData() async {
        syncingData = true
        syncingError = nil
        updateUIInLoadingState()
        waitingTracker = WaitingTimeTracker(trackScenario: .dashboardTopPerformers)
        do {
            try await syncTopEarnersStats()
            syncingDidFinishPublisher.send(nil)
        } catch {
            syncingError = error
            syncingDidFinishPublisher.send(error)
            DDLogError("⛔️ Dashboard (Top Performers) — Error synchronizing top earner stats: \(error)")
        }
        syncingData = false
        updateUIInLoadedState()
    }

    func dismissTopPerformers() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .topPerformers))
        onDismiss?()
    }

    func trackInteraction() {
        analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .topPerformers))
        usageTracksEventEmitter.interacted()
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
    func observeSyncingCompletion() {
        syncingDidFinishPublisher
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] error in
                guard let self else { return }
                if error == nil {
                    analytics.track(event: .Dashboard.dashboardTopPerformersLoaded(timeRange: timeRange))
                }
                waitingTracker?.end()
            }
            .store(in: &subscriptions)
    }

    @MainActor
    func loadLastTimeRange() async -> StatsTimeRangeV4? {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadLastSelectedTopPerformersTimeRange(siteID: siteID) { timeRange in
                continuation.resume(returning: timeRange)
            }
            stores.dispatch(action)
        }
    }

    func saveLastTimeRange(_ timeRange: StatsTimeRangeV4) {
        let action = AppSettingsAction.setLastSelectedTopPerformersTimeRange(siteID: siteID, timeRange: timeRange)
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
        periodViewModel.update(state: .loading)
    }

    func updateUIInLoadedState() {
        guard !syncingData else {
            return
        }
        guard let items = topEarnerStats?.items?.sorted(by: >), items.isNotEmpty else {
            return periodViewModel.update(state: .loaded(rows: []))
        }
        periodViewModel.update(state: .loaded(rows: items))
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
            stores.dispatch(StatsActionV4.retrieveTopEarnerStats(siteID: siteID,
                                                                 timeRange: timeRange,
                                                                 timeZone: siteTimezone,
                                                                 earliestDateToInclude: earliestDateToInclude,
                                                                 latestDateToInclude: latestDateToInclude,
                                                                 quantity: Constants.topEarnerStatsLimit,
                                                                 forceRefresh: true,
                                                                 saveInStorage: true,
                                                                 onCompletion: { result in
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
