import Combine
import UIKit
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

    /// Currently applied analytics order date type. Defaults to `.paid` (the WooCommerce backend default)
    /// while the value is being loaded for the first time.
    @Published private(set) var orderType: AnalyticsOrderDateType = .paid

    /// Currently selected revenue metric on the Performance card. Defaults to `.total` which matches
    /// the existing card behavior (API's `total_sales`). Persisted per-site via `AppSettingsAction`.
    @Published private(set) var revenueType: DashboardRevenueStatsType = .total

    /// The order type whose update is currently in flight, if any. Used by the bottom sheet to render
    /// an inline progress indicator next to the row being saved and to disable other rows while a
    /// save is in progress.
    @Published private(set) var updatingOrderType: AnalyticsOrderDateType?

    /// Set when the most recent order type update fails. Cleared when a save succeeds or when the
    /// merchant initiates a new selection.
    @Published var orderTypeUpdateError: Error?

    /// Tracks whether the merchant has manually picked an order type during this session.
    /// Prevents a late-arriving initial `loadOrderType` from clobbering a user selection.
    private var hasUserSelectedOrderType = false

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
    /// Cleared every time `observePeriodViewModel()` runs so the previous period view model's
    /// pipelines stop writing to the parent's `@Published` properties. Without this, the chart
    /// pipeline (which combines with `$revenueType`) re-fires from leaked period VMs on every
    /// metric switch and overwrites the current data with empty values.
    private var periodViewModelSubscriptions: Set<AnyCancellable> = []
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

        // Seed from the locally cached SiteSetting (written by SettingStoreMethods on every
        // successful retrieve/update) to avoid showing the default `.paid` for the network
        // round-trip when the merchant has previously saved a different value. `loadOrderType`
        // still runs and reconciles with the server.
        if let cached = AnalyticsOrderDateType.cachedValue(siteID: siteID, storageManager: storageManager) {
            self.orderType = cached
        }

        observeSyncingCompletion()
        observeData()
        observeChartValueSelectedEvents()

        Task { @MainActor in
            self.timeRange = await loadLastTimeRange() ?? .today
        }

        Task { @MainActor in
            await loadOrderType()
        }

        Task { @MainActor in
            self.revenueType = await loadLastRevenueType() ?? .total
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

        // Stop if data is relatively new (unless forceRefresh)
        if !forceRefresh && DashboardTimestampStore.isTimestampFresh(for: .performance, at: timeRange.timestampRange) {

            // We can show the cached data since we know it's available from the timestamp.
            updateSiteVisitStatMode()

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
            updateSiteVisitStatMode()

            // Reload the Store Info Widget after syncing the today's stats.
            if case .today = timeRange {
                WidgetCenter.shared.reloadTimelines(ofKind: WooConstants.storeInfoWidgetKind)
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

    /// Tracks the tap on the Performance card order date type selector label.
    func trackOrderDateTypeSelectorTapped() {
        analytics.track(event: .Dashboard.performanceCardOrderDateTypeSelectorTapped())
    }

    /// Switches the displayed revenue metric and persists the choice for next launch. No-op if the
    /// metric matches the current selection. Switching invalidates the highlighted chart point so the
    /// merchant sees the totals for the new metric in the header instead of a stale data point.
    func didSelectRevenueType(_ newRevenueType: DashboardRevenueStatsType) {
        guard revenueType != newRevenueType else { return }

        revenueType = newRevenueType
        periodViewModel?.revenueType = newRevenueType

        // Clear any selected chart interval so the card header reverts to the period total for the new metric.
        didSelectStatsInterval(at: nil)

        let action = AppSettingsAction.setLastSelectedDashboardRevenueStatsType(siteID: siteID, revenueType: newRevenueType)
        stores.dispatch(action)

        trackInteraction()
        analytics.track(event: .Dashboard.dashboardStatsRevenueTypeSelected(revenueType: newRevenueType))
    }

    /// Handles the merchant tapping a row in the order date type bottom sheet.
    ///
    /// Returns `true` when the bottom sheet should dismiss:
    /// - the tapped option is already selected (no save round-trip needed), or
    /// - the save succeeded.
    ///
    /// Returns `false` when the save failed so the sheet stays open and the inline error remains visible.
    @MainActor
    func handleOrderTypeSelection(_ newOrderType: AnalyticsOrderDateType) async -> Bool {
        // Tapping the currently-selected row just dismisses; nothing to save.
        if orderType == newOrderType {
            return true
        }
        await updateOrderType(newOrderType)
        // Dismiss only if the save actually took effect on the view model.
        return orderType == newOrderType
    }

    /// Updates the analytics order date type setting and refreshes dashboard stats.
    /// On failure, sets `orderTypeUpdateError` so the bottom sheet can present an inline error.
    @MainActor
    private func updateOrderType(_ newOrderType: AnalyticsOrderDateType) async {
        guard updatingOrderType == nil else { return }
        hasUserSelectedOrderType = true
        updatingOrderType = newOrderType
        orderTypeUpdateError = nil
        defer { updatingOrderType = nil }
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let action = SettingAction.updateAnalyticsOrderDateType(siteID: siteID, value: newOrderType) { result in
                    continuation.resume(with: result)
                }
                stores.dispatch(action)
            }
            orderType = newOrderType
            // Tracked only after a successful API update — matches Android, where the event fires on save success.
            analytics.track(event: .Dashboard.performanceCardOrderDateTypeSelected(newOrderType))
            // Server-side filter changed: invalidate the cached timestamp so the next sync hits the network.
            DashboardTimestampStore.removeTimestamp(for: .performance, at: timeRange.timestampRange)
            await reloadDataIfNeeded(forceRefresh: true)
        } catch {
            DDLogError("⛔️ Error updating analytics order date type: \(error)")
            orderTypeUpdateError = error
            analytics.track(event: .Dashboard.performanceCardOrderDateTypeUpdateFailed(error: error))
        }
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
                if let event = waitingTracker?.end() {
                    analytics.track(event: event)
                }
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
                let viewModel = StoreStatsPeriodViewModel(siteID: siteID,
                                                          timeRange: timeRange,
                                                          siteTimezone: siteTimezone,
                                                          currentDate: currentDate,
                                                          currencyFormatter: currencyFormatter,
                                                          currencySettings: currencySettings,
                                                          storageManager: storageManager)
                // Carry the current revenue metric over to the freshly created period VM so the
                // revenue text reflects the merchant's choice immediately on time-range switches.
                viewModel.revenueType = revenueType
                return viewModel
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
        periodViewModelSubscriptions.removeAll()

        guard let periodViewModel else {
            return
        }

        periodViewModel.timeRangeBarViewModel
            .map { $0.timeRangeText }
            .sink { [weak self] in self?.timeRangeText = $0 }
            .store(in: &periodViewModelSubscriptions)

        periodViewModel.timeRangeBarViewModel
            .map { $0.selectedDateText }
            .sink { [weak self] in self?.selectedDateText = $0 }
            .store(in: &periodViewModelSubscriptions)

        periodViewModel.revenueStatsText
            .sink { [weak self] in self?.revenueStatsText = $0 }
            .store(in: &periodViewModelSubscriptions)

        periodViewModel.orderStatsText
            .sink { [weak self] in self?.orderStatsText = $0 }
            .store(in: &periodViewModelSubscriptions)

        periodViewModel.visitorStatsText
            .sink { [weak self] in self?.visitorStatsText = $0 }
            .store(in: &periodViewModelSubscriptions)

        periodViewModel.conversionStatsText
            .sink { [weak self] in self?.conversionStatsText = $0 }
            .store(in: &periodViewModelSubscriptions)

        Publishers.CombineLatest(periodViewModel.orderStatsIntervals.removeDuplicates(), $revenueType)
            .map { [weak self] intervals, revenueType in
                guard let self else {
                    return []
                }
                return createOrderStatsIntervalData(orderStatsIntervals: intervals, revenueType: revenueType)
            }
            .sink { [weak self] in self?.statsIntervalData = $0 }
            .store(in: &periodViewModelSubscriptions)
    }

    func createOrderStatsIntervalData(orderStatsIntervals: [OrderStatsV4Interval],
                                      revenueType: DashboardRevenueStatsType) -> [StoreStatsChartData] {
            let intervalDates = orderStatsIntervals.map { $0.dateStart(timeZone: siteTimezone) }
            let revenues = orderStatsIntervals.map { ($0.revenueValue(for: revenueType) as NSDecimalNumber).doubleValue }
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

    /// Loads the merchant's previously selected revenue metric for the Performance card.
    /// Returns `nil` if the merchant has not yet picked one — callers should fall back to `.total`.
    @MainActor
    func loadLastRevenueType() async -> DashboardRevenueStatsType? {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadLastSelectedDashboardRevenueStatsType(siteID: siteID) { revenueType in
                continuation.resume(returning: revenueType)
            }
            stores.dispatch(action)
        }
    }

    /// Loads the current analytics order date type from the backend. Falls back to the existing
    /// `orderType` value (default `.paid`) if the request fails — the merchant still gets a usable
    /// default and can re-open the bottom sheet to retry.
    @MainActor
    func loadOrderType() async {
        do {
            let dateType: AnalyticsOrderDateType = try await withCheckedThrowingContinuation { continuation in
                let action = SettingAction.retrieveAnalyticsOrderDateType(siteID: siteID) { result in
                    continuation.resume(with: result)
                }
                stores.dispatch(action)
            }
            // If the merchant already changed the order type while the initial fetch was in flight,
            // honor their selection rather than overwriting it with the stale server value.
            guard !hasUserSelectedOrderType else { return }
            orderType = dateType
        } catch {
            DDLogWarn("⚠️ Could not fetch analytics order date type, falling back to default: \(error)")
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

    func updateSiteVisitStatMode() {
        switch timeRange {
        case .custom:
            updateSiteVisitStatModeForCustomRange()
        case .today, .thisWeek, .thisMonth, .thisYear:
            siteVisitStatMode = .default
        }
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
            ServiceLocator.startupWaitingTimeTracker.endWithoutTracking()
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
