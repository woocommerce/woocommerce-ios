import Combine
import WidgetKit
import WooFoundation
import Yosemite
import protocol Storage.StorageManagerType
import enum Storage.StatsVersion
import enum Networking.DotcomError

/// View model for `StorePerformanceView`.
///
final class StorePerformanceViewModel: ObservableObject {
    @Published private(set) var timeRange = StatsTimeRangeV4.today
    @Published private(set) var statsIntervalData: [StoreStatsChartData] = []

    @Published private(set) var timeRangeText = ""
    @Published private(set) var revenueStatsText = ""
    @Published private(set) var orderStatsText = ""
    @Published private(set) var visitorStatsText = ""
    @Published private(set) var conversionStatsText = ""

    @Published private(set) var syncingData = false
    @Published private(set) var siteVisitStatMode = SiteVisitStatsMode.hidden
    @Published private(set) var statsVersion: StatsVersion = .v4

    let siteID: Int64
    let siteTimezone: TimeZone
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter
    private let currencySettings: CurrencySettings

    private var periodViewModel: StoreStatsPeriodViewModel?

    // Set externally to trigger callback when data is being synced.
    var onDataReload: () -> Void = {}

    // Set externally to trigger callback when syncing fails.
    var onSyncingError: (Error) -> Void = { _ in }

    private var subscriptions: Set<AnyCancellable> = []
    private var currentDate = Date()

    init(siteID: Int64,
         siteTimezone: TimeZone = .siteTimezone,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.siteID = siteID
        self.stores = stores
        self.siteTimezone = siteTimezone
        self.storageManager = storageManager
        self.currencyFormatter = currencyFormatter
        self.currencySettings = currencySettings

        observeTimeRange()

        Task { @MainActor in
            self.timeRange = await loadLastTimeRange() ?? .today
        }
    }

    func didSelectTimeRange(_ newTimeRange: StatsTimeRangeV4) {
        timeRange = newTimeRange
        saveLastTimeRange(timeRange)
    }

    func didSelectStatsInterval(at index: Int?) {
        periodViewModel?.selectedIntervalIndex = index
    }

    @MainActor
    func reloadData() async {
        onDataReload()
        syncingData = true
        do {
            try await syncAllStats()
            siteVisitStatMode = .default
            trackDashboardStatsSyncComplete()
            if timeRange == .today {
                WidgetCenter.shared.reloadTimelines(ofKind: WooConstants.storeInfoWidgetKind)
            }
        } catch {
            DDLogError("⛔️ Error loading store stats: \(error)")
            handleSyncError(error: error)
        }
        syncingData = false
    }
}

// MARK: - Data for `StorePerformanceView`
//
extension StorePerformanceViewModel {
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

    var chartViewModel: StoreStatsChartViewModel {
        StoreStatsChartViewModel(intervals: statsIntervalData,
                                 timeRange: timeRange,
                                 currencySettings: currencySettings,
                                 currencyFormatter: currencyFormatter)
    }
}

// MARK: - Private helpers
//
private extension StorePerformanceViewModel {
    func observeTimeRange() {
        $timeRange
            .compactMap { [weak self] timeRange -> StoreStatsPeriodViewModel? in
                guard let self else {
                    return nil
                }
                return StoreStatsPeriodViewModel(siteID: siteID,
                                                 timeRange: timeRange,
                                                 siteTimezone: siteTimezone,
                                                 currentDate: currentDate,
                                                 currencyFormatter: currencyFormatter,
                                                 currencySettings: currencySettings,
                                                 storageManager: storageManager)
            }
            .sink { [weak self] viewModel in
                guard let self else { return }
                periodViewModel = viewModel
                observePeriodViewModel()
                Task { [weak self] in
                    await self?.reloadData()
                }
            }
            .store(in: &subscriptions)
    }

    func observePeriodViewModel() {
        guard let periodViewModel else {
            return
        }

        periodViewModel.timeRangeBarViewModel
            .map { $0.timeRangeText }
            .assign(to: &$timeRangeText)

        periodViewModel.revenueStatsText
            .assign(to: &$revenueStatsText)

        periodViewModel.orderStatsText
            .assign(to: &$orderStatsText)

        periodViewModel.visitorStatsText
            .assign(to: &$visitorStatsText)

        periodViewModel.conversionStatsText
            .assign(to: &$conversionStatsText)

        periodViewModel.orderStatsIntervals
            .map { [weak self] intervals in
                guard let self else {
                    return []
                }
                return createOrderStatsIntervalData(orderStatsIntervals: intervals)
            }
            .assign(to: &$statsIntervalData)
    }

    func createOrderStatsIntervalData(orderStatsIntervals: [OrderStatsV4Interval]) -> [StoreStatsChartData] {
            let intervalDates = orderStatsIntervals.map { $0.dateStart(timeZone: siteTimezone) }
            let revenues = orderStatsIntervals.map { ($0.revenueValue as NSDecimalNumber).doubleValue }
            return zip(intervalDates, revenues)
                .map { x, y -> StoreStatsChartData in
                    .init(date: x, revenue: y)
                }
        }

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
}

// MARK: - Syncing data
//
private extension StorePerformanceViewModel {
    @MainActor
    func syncAllStats() async throws {
        currentDate = Date()
        let timezoneForSync = TimeZone.siteTimezone
        let latestDateToInclude = timeRange.latestDate(currentDate: currentDate, siteTimezone: timezoneForSync)

        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor [weak self] in
                guard let self else { return }
                statsVersion = await syncStats(latestDateToInclude: latestDateToInclude)
            }

            group.addTask { [weak self] in
                try await self?.syncSiteVisitStats(latestDateToInclude: latestDateToInclude)
            }

            group.addTask { [weak self] in
                try await self?.syncSiteSummaryStats(latestDateToInclude: latestDateToInclude)
            }
        }
    }

    /// Syncs store stats for dashboard UI.
    @MainActor
    func syncStats(latestDateToInclude: Date) async -> StatsVersion {
        let waitingTracker = WaitingTimeTracker(trackScenario: .dashboardMainStats)
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        return await withCheckedContinuation { continuation in
            stores.dispatch(StatsActionV4.retrieveStats(siteID: siteID,
                                                        timeRange: timeRange,
                                                        timeZone: siteTimezone,
                                                        earliestDateToInclude: earliestDateToInclude,
                                                        latestDateToInclude: latestDateToInclude,
                                                        quantity: timeRange.maxNumberOfIntervals,
                                                        forceRefresh: true,
                                                        onCompletion: { result in
                switch result {
                case .success:
                    waitingTracker.end()
                    continuation.resume(returning: StatsVersion.v4)
                case .failure(let error):
                    DDLogError("⛔️ Dashboard (Order Stats) — Error synchronizing order stats v4: \(error)")
                    if error as? DotcomError == .noRestRoute {
                        continuation.resume(returning: StatsVersion.v3)
                    } else {
                        continuation.resume(returning: StatsVersion.v4)
                    }
                }
            }))
        }
    }

    /// Syncs visitor stats for dashboard UI.
    @MainActor
    func syncSiteVisitStats(latestDateToInclude: Date) async throws {
        guard stores.isAuthenticatedWithoutWPCom == false else { // Visit stats are only available for stores connected to WPCom
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(StatsActionV4.retrieveSiteVisitStats(siteID: siteID,
                                                                 siteTimezone: siteTimezone,
                                                                 timeRange: timeRange,
                                                                 latestDateToInclude: latestDateToInclude,
                                                                 onCompletion: { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
                }
                continuation.resume(with: result)
            }))
        }
    }

    /// Syncs summary stats for dashboard UI.
    @MainActor
    func syncSiteSummaryStats(latestDateToInclude: Date) async throws {
        guard stores.isAuthenticatedWithoutWPCom == false else { // Summary stats are only available for stores connected to WPCom
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(StatsActionV4.retrieveSiteSummaryStats(siteID: siteID,
                                                                   siteTimezone: siteTimezone,
                                                                   period: timeRange.summaryStatsGranularity,
                                                                   quantity: 1,
                                                                   latestDateToInclude: latestDateToInclude,
                                                                   saveInStorage: true) { result in
                   if case let .failure(error) = result {
                       DDLogError("⛔️ Error synchronizing summary stats: \(error)")
                   }

                   let voidResult = result.map { _ in () } // Caller expects no entity in the result.
                continuation.resume(with: voidResult)
               })
        }
    }

    private func handleSyncError(error: Error) {
        switch error {
        case let siteStatsStoreError as SiteStatsStoreError:
            handleSiteStatsStoreError(error: siteStatsStoreError)
        default:
            onSyncingError(error)
            trackDashboardStatsSyncComplete(withError: error)
        }
    }

    func handleSiteStatsStoreError(error: SiteStatsStoreError) {
        switch error {
        case .noPermission:
            siteVisitStatMode = .hidden
            trackDashboardStatsSyncComplete()
        case .statsModuleDisabled:
            let defaultSite = stores.sessionManager.defaultSite
            if defaultSite?.isJetpackCPConnected == true {
                siteVisitStatMode = .redactedDueToJetpack
            } else {
                siteVisitStatMode = .hidden
            }
            trackDashboardStatsSyncComplete()
        default:
            onSyncingError(error)
            trackDashboardStatsSyncComplete(withError: error)
        }
    }

    /// Notifies `AppStartupWaitingTimeTracker` when dashboard sync is complete.
    ///
    func trackDashboardStatsSyncComplete(withError error: Error? = nil) {
        guard error == nil else { // Stop the tracker if there is an error.
            ServiceLocator.startupWaitingTimeTracker.end()
            return
        }
        ServiceLocator.startupWaitingTimeTracker.end(action: .syncDashboardStats)
    }
}

// MARK: Constants
//
private extension StorePerformanceViewModel {
    enum Constants {
        static let thirtyDaysInSeconds: TimeInterval = 86400*30
    }
    enum Localization {
        static let addCustomRange = NSLocalizedString(
            "storePerformanceViewModel.addCustomRange",
            value: "Add",
            comment: "Button in date range picker to add a Custom Range tab"
        )
    }
}
