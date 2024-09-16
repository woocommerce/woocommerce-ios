import Combine
import WidgetKit
import WooFoundation
import Yosemite
import protocol Storage.StorageManagerType
import enum Storage.StatsVersion
import enum Networking.DotcomError
import enum Networking.NetworkError

/// Different display modes of site visit stats
///
enum SiteVisitStatsMode {
    case `default`
    case redactedDueToJetpack
    case hidden
    case redactedDueToCustomRange
}

/// View model for `StorePerformanceView`.
///
@MainActor
final class StorePerformanceViewModel: ObservableObject {
    @Published private(set) var timeRange = StatsTimeRangeV4.today
    @Published private(set) var statsIntervalData: [StoreStatsChartData] = []

    @Published private(set) var timeRangeText = ""
    @Published private(set) var revenueStatsText = ""
    @Published private(set) var orderStatsText = ""
    @Published private(set) var visitorStatsText = ""
    @Published private(set) var conversionStatsText = ""

    @Published private(set) var selectedDateText: String?
    @Published private(set) var shouldHighlightStats = false

    @Published private(set) var syncingData = false
    @Published private(set) var siteVisitStatMode = SiteVisitStatsMode.hidden
    @Published private(set) var analyticsEnabled = true

    @Published private(set) var loadingError: Error?

    let siteID: Int64
    let siteTimezone: TimeZone
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter
    private let currencySettings: CurrencySettings
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter
    private let analytics: Analytics

    private var periodViewModel: StoreStatsPeriodViewModel?
    private(set) var chartViewModel: StoreStatsChartViewModel?

    // Set externally to trigger callback when hiding the card.
    var onDismiss: (() -> Void)?

    private var subscriptions: Set<AnyCancellable> = []
    private var currentDate = Date()
    private let chartValueSelectedEventsSubject = PassthroughSubject<Int?, Never>()

    private var waitingTracker: WaitingTimeTracker?
    private let syncingDidFinishPublisher = PassthroughSubject<Error?, Never>()

    // To check whether the tab is showing the visitors and conversion views as redacted for custom range.
    // This redaction is only shown on Custom Range tab with WordPress.com or Jetpack connected sites,
    // while Jetpack CP sites has its own redacted for Jetpack state, and non-Jetpack sites simply has them empty.
    var unavailableVisitStatsDueToCustomRange: Bool {
        guard timeRange.isCustomTimeRange,
              let site = stores.sessionManager.defaultSite,
              site.isJetpackConnected,
              site.isJetpackThePluginInstalled else {
            return false
        }
        return true
    }

    /// Determines if the redacted state should be shown.
    /// `True`when fetching data for the first time, otherwise `false` as cached data should be presented.
    ///
    var showRedactedState: Bool {
        return syncingData && periodViewModel?.noDataFound == true
    }

    /// Returns the last updated timestamp for the current time range.
    ///
    var lastUpdatedTimestamp: String {
        guard let timestamp = DashboardTimestampStore.loadTimestamp(for: .performance, at: timeRange.timestampRange) else {
            return ""
        }

        let formatter = timestamp.isSameDay(as: .now) ? DateFormatter.timeFormatter : DateFormatter.dateAndTimeFormatter
        return formatter.string(from: timestamp)
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
        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.analytics = analytics

        observeSyncingCompletion()
        observeData()
        observeChartValueSelectedEvents()

        Task { @MainActor in
            self.timeRange = await loadLastTimeRange() ?? .today
        }
    }

    func didSelectTimeRange(_ newTimeRange: StatsTimeRangeV4) {
        guard timeRange != newTimeRange else { return }

        timeRange = newTimeRange
        saveLastTimeRange(timeRange)

        Task { [weak self] in
            await self?.reloadDataIfNeeded()
        }

        shouldHighlightStats = false
        analytics.track(event: .Dashboard.dashboardMainStatsDate(timeRange: timeRange))
    }

    func didSelectStatsInterval(at index: Int?) {
        chartValueSelectedEventsSubject.send(index)
        periodViewModel?.selectedIntervalIndex = index
        shouldHighlightStats = index != nil

        if unavailableVisitStatsDueToCustomRange {
            // If time range is less than 2 days, redact data when selected and show when deselected.
            // Otherwise, show data when selected and redact when deselected.
            guard case let .custom(from, to) = timeRange,
                  let differenceInDays = StatsTimeRangeV4.differenceInDays(startDate: from, endDate: to) else {
                return
            }

            if differenceInDays == .sameDay {
                siteVisitStatMode = index != nil ? .hidden : .default
            } else {
                siteVisitStatMode = index != nil ? .default : .redactedDueToCustomRange
            }
        }
    }

    /// Reloads the card data if significantly time has passed.
    /// Set `forceRefresh` to `true` to always sync data, useful for pull to refresh scenarios.
    @MainActor
    func reloadDataIfNeeded(forceRefresh: Bool = false) async {

        // Preemptively show any cached content
        periodViewModel?.loadCachedContent()

        // Stop if data is relatively new
        if !forceRefresh && DashboardTimestampStore.isTimestampFresh(for: .performance, at: timeRange.timestampRange) {
            return
        }

        syncingData = true
        loadingError = nil
        waitingTracker = WaitingTimeTracker(trackScenario: .dashboardMainStats)
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .performance))
        do {
            currentDate = .now // Legacy code from when code was outside of `PerformanceCardDataSyncUseCase`
            let syncUseCase = PerformanceCardDataSyncUseCase(siteID: siteID, siteTimezone: siteTimezone, timeRange: timeRange, stores: stores)
            try await syncUseCase.sync()

            trackDashboardStatsSyncComplete()
            analyticsEnabled = true
            switch timeRange {
            case .custom:
                updateSiteVisitStatModeForCustomRange()
            case .today:
                // Reload the Store Info Widget after syncing the today's stats.
                WidgetCenter.shared.reloadTimelines(ofKind: WooConstants.storeInfoWidgetKind)
                fallthrough
            case .thisWeek, .thisMonth, .thisYear:
                siteVisitStatMode = .default
            }
            syncingDidFinishPublisher.send(nil)
        } catch {
            switch error {
            case DotcomError.noRestRoute, NetworkError.notFound:
                analyticsEnabled = false
            default:
                analyticsEnabled = true
                handleSyncError(error: error)
            }
            DDLogError("⛔️ Error loading store stats: \(error)")
            syncingDidFinishPublisher.send(error)
        }
        syncingData = false
    }

    func hideStorePerformance() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .performance))
        onDismiss?()
    }

    /// Adds necessary tracking for the interaction
    func trackInteraction() {
        usageTracksEventEmitter.interacted()
        analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .performance))
    }

    /// To be triggered from the UI for custom range related events
    func trackCustomRangeEvent(_ event: WooAnalyticsEvent) {
        analytics.track(event: event)
    }

    func onViewAppear() {
        /// tracks `used_analytics`
        usageTracksEventEmitter.interacted()
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

    var granularityText: String? {
        guard case .custom = timeRange else {
            return nil
        }
        return timeRange.intervalGranularity.displayText
    }

    var redactedViewIcon: UIImage? {
        switch siteVisitStatMode {
        case .redactedDueToJetpack:
            UIImage.jetpackLogoImage.withRenderingMode(.alwaysTemplate)
        case .redactedDueToCustomRange:
            UIImage.infoOutlineImage.withRenderingMode(.alwaysTemplate)
        case .default, .hidden:
            nil
        }
    }

    var redactedViewIconColor: UIColor {
        siteVisitStatMode == .redactedDueToJetpack ? .jetpackGreen : .accent
    }

    var hasRevenue: Bool {
        guard let chartViewModel else {
            return false
        }
        return chartViewModel.hasRevenue
    }
}

// MARK: - Private helpers
//
private extension StorePerformanceViewModel {
    func observeSyncingCompletion() {
        syncingDidFinishPublisher
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] error in
                guard let self else { return }
                waitingTracker?.end()
                analytics.track(event: .Dashboard.dashboardMainStatsLoaded(timeRange: timeRange))
                if let error {
                    analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .performance, error: error))
                } else {
                    analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .performance))
                }
            }
            .store(in: &subscriptions)
    }

    func observeData() {
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
            }
            .store(in: &subscriptions)

        $statsIntervalData
            .map { [weak self] data -> StoreStatsChartViewModel? in
                guard let self else {
                    return nil
                }
                return StoreStatsChartViewModel(intervals: data,
                                                timeRange: timeRange,
                                                currencySettings: currencySettings,
                                                currencyFormatter: currencyFormatter)
            }
            .sink { [weak self] viewModel in
                self?.chartViewModel = viewModel
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

        periodViewModel.timeRangeBarViewModel
            .map { $0.selectedDateText }
            .assign(to: &$selectedDateText)

        periodViewModel.revenueStatsText
            .assign(to: &$revenueStatsText)

        periodViewModel.orderStatsText
            .assign(to: &$orderStatsText)

        periodViewModel.visitorStatsText
            .assign(to: &$visitorStatsText)

        periodViewModel.conversionStatsText
            .assign(to: &$conversionStatsText)

        periodViewModel.orderStatsIntervals
            .removeDuplicates()
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
            let action = AppSettingsAction.loadLastSelectedPerformanceTimeRange(siteID: siteID) { timeRange in
                continuation.resume(returning: timeRange)
            }
            stores.dispatch(action)
        }
    }

    func saveLastTimeRange(_ timeRange: StatsTimeRangeV4) {
        let action = AppSettingsAction.setLastSelectedPerformanceTimeRange(siteID: siteID, timeRange: timeRange)
        stores.dispatch(action)

        // Assume we don't have a timestamp for a new custom range since we don't support saving multiple custom ranges timestamps.
        if timeRange.timestampRange == .custom {
            DashboardTimestampStore.removeTimestamp(for: .performance, at: .custom)
        }
    }

    /// Initial redaction state logic for site visit stats.
    /// If a) Site is WordPress.com site or self-hosted site with Jetpack:
    ///       - if date range is < 2 days, we can show the visit stats (because the data will be correct)
    ///       - else, set as `.redactedDueToCustomRange`
    ///    b). Site is Jetpack CP, set as `.redactedDueToJetpack`
    ///    c). Site is a non-Jetpack site: set as `.hidden`
    func updateSiteVisitStatModeForCustomRange() {
        guard let site = stores.sessionManager.defaultSite,
              case let .custom(startDate, endDate) = timeRange else { return }

        if site.isJetpackConnected && site.isJetpackThePluginInstalled {
            let differenceInDay = StatsTimeRangeV4.differenceInDays(startDate: startDate, endDate: endDate)
            siteVisitStatMode = differenceInDay == .sameDay ? .default : .redactedDueToCustomRange
        } else if site.isJetpackCPConnected {
            siteVisitStatMode = .redactedDueToJetpack
        } else {
            siteVisitStatMode = .hidden
        }
    }

    /// Observe `chartValueSelected` events and call `StoreStatsUsageTracksEventEmitter.interacted()` when
    /// no similar events have been received after some time.
    ///
    /// We debounce it because there are just too many events received from `chartValueSelected()` when
    /// the user holds and drags on the chart. Having too many events might skew the
    /// `StoreStatsUsageTracksEventEmitter` algorithm.
    func observeChartValueSelectedEvents() {
        chartValueSelectedEventsSubject
            .debounce(for: .seconds(Constants.chartValueSelectedEventsDebounce), scheduler: DispatchQueue.main)
            .sink { [weak self] index in
                self?.handleSelectedChartValue(at: index)
            }
            .store(in: &subscriptions)
    }

    func handleSelectedChartValue(at index: Int?) {
        if timeRange.isCustomTimeRange {
            analytics.track(event: .DashboardCustomRange.interacted())
        }
        trackInteraction()
    }
}

// MARK: - Syncing data
//
private extension StorePerformanceViewModel {
    private func handleSyncError(error: Error) {
        switch error {
        case let siteStatsStoreError as SiteStatsStoreError:
            handleSiteStatsStoreError(error: siteStatsStoreError)
        default:
            loadingError = error
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
            loadingError = error
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

        /// The wait time before the `StoreStatsUsageTracksEventEmitter.interacted()` is called.
        static let chartValueSelectedEventsDebounce: TimeInterval = 0.5
    }
    enum Localization {
        static let addCustomRange = NSLocalizedString(
            "storePerformanceViewModel.addCustomRange",
            value: "Add",
            comment: "Button in date range picker to add a Custom Range tab"
        )
    }
}
