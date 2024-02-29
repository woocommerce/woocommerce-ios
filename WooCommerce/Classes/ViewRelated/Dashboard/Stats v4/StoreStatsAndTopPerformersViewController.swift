import Combine
import Experiments
import UIKit
import Yosemite
import class WidgetKit.WidgetCenter

/// Top-level stats container view controller that consists of a button bar with 4 time ranges.
/// Each time range tab is managed by a `StoreStatsAndTopPerformersPeriodViewController`.
///
final class StoreStatsAndTopPerformersViewController: TabbedViewController {
    // MARK: - DashboardUI protocol

    var displaySyncingError: (Error) -> Void = { _ in }

    var onPullToRefresh: @MainActor () async -> Void = {}

    private var customRangeCoordinator: CustomRangeTabCreationCoordinator?

    // MARK: - Subviews

    private lazy var buttonBarBottomBorder: UIView = {
        return createBorderView()
    }()

    // MARK: - Calculated Properties

    private var visibleChildViewController: StoreStatsAndTopPerformersPeriodViewController {
        return periodVCs[selection]
    }

    // MARK: - Private Properties

    private var periodVCs: [StoreStatsAndTopPerformersPeriodViewController]
    private let siteID: Int64
    // A set of syncing time ranges is tracked instead of a single boolean so that the stats for each time range
    // can be synced when swiping or tapping to change the time range tab before the syncing finishes for the previously selected tab.
    private var syncingTimeRanges: Set<StatsTimeRangeV4> = []
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter
    private let dashboardViewModel: DashboardViewModel
    private var timeRanges: [StatsTimeRangeV4] = [.today, .thisWeek, .thisMonth, .thisYear]
    private let featureFlagService: FeatureFlagService

    /// Because loading the last selected time range tab is async, the selected tab index is initially `nil` and set after the last selected value is loaded.
    /// We need to make sure any call to the public `reloadData` is after the selected time range is set to avoid making unnecessary API requests
    /// for the non-selected tab.
    @Published private var selectedTimeRangeIndex: Int?
    /// The index of the selected tab in the tab bar. `selectedTimeRangeIndex` is an observable version of this.
    override var selection: Int {
        didSet {
            selectedTimeRangeIndex = selection
        }
    }
    private var selectedTimeRangeIndexSubscription: AnyCancellable?

    private let pushNotificationsManager: PushNotesManager
    private var localOrdersSubscription: AnyCancellable?
    private var remoteOrdersSubscription: AnyCancellable?

    private lazy var customRangeButtonView = createCustomRangeButtonView()

    private let stores: StoresManager

    // MARK: - View Lifecycle

    init(siteID: Int64,
         dashboardViewModel: DashboardViewModel,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.dashboardViewModel = dashboardViewModel
        self.pushNotificationsManager = pushNotificationsManager

        self.usageTracksEventEmitter = usageTracksEventEmitter
        self.featureFlagService = featureFlagService
        self.stores = stores

        let currentDate = Date()

        let tabItems: [TabbedItem] = timeRanges.map { timeRange in
            let viewController = StoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                                timeRange: timeRange,
                                                                                currentDate: currentDate,
                                                                                canDisplayInAppFeedbackCard: timeRange == .today,
                                                                                usageTracksEventEmitter: usageTracksEventEmitter,
                                                                                onEditCustomTimeRange: nil)
            return .init(title: timeRange.tabTitle,
                         viewController: viewController,
                         accessibilityIdentifier: "period-data-" + timeRange.rawValue + "-tab")
        }
        periodVCs = tabItems.compactMap { $0.viewController as? StoreStatsAndTopPerformersPeriodViewController }
        super.init(items: tabItems, tabSizingStyle: .fitting)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureTabBar()
        configurePeriodViewControllers()
        observeRemotelyCreatedOrdersToResetLastSyncTimestamp()
        observeLocallyCreatedOrdersToResetLastSyncTimestamp()

        Task { @MainActor in
            await configureCustomRangeTab()
            let selectedTimeRange = await loadLastTimeRange() ?? .today
            // Defaults to the Today tab if cannot find the selected time range.
            let selectedTabIndex = timeRanges.firstIndex(of: selectedTimeRange) ?? 0
            selection = selectedTabIndex
            observeSelectedTimeRangeIndex()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ensureGhostContentIsAnimated()
    }
}

extension StoreStatsAndTopPerformersViewController: DashboardUI {
    @MainActor
    func reloadData(forced: Bool) async {
        await withCheckedContinuation { continuation in
            syncAllStats(forced: forced) { _ in
                continuation.resume(returning: ())
            }
        }
    }

    func remindStatsUpgradeLater() {
        // No op as this VC represents the latest stats version to date.
    }
}

// MARK: - Syncing Data
//
private extension StoreStatsAndTopPerformersViewController {
    func observeSelectedTimeRangeIndex() {
        selectedTimeRangeIndexSubscription = $selectedTimeRangeIndex
            .compactMap { $0 }
            // It's possible to reach an out-of-bound index by swipe gesture, thus checking the index range here.
            .filter { $0 >= 0 && $0 < self.timeRanges.count }
            .removeDuplicates()
            // Tapping to change to a farther tab could result in `updateIndicator` callback to be triggered for the middle tabs.
            // A short debounce workaround is applied here to avoid making API requests for the middle tabs.
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] timeRangeTabIndex in
                guard let self else { return }
                let periodViewController = self.periodVCs[timeRangeTabIndex]
                self.saveLastTimeRange(periodViewController.timeRange)
                self.syncStats(forced: false, viewControllerToSync: periodViewController)
            }
    }

    func syncAllStats(forced: Bool, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        syncStats(forced: forced, viewControllerToSync: visibleChildViewController, onCompletion: onCompletion)
    }

    func syncStats(forced: Bool, viewControllerToSync: StoreStatsAndTopPerformersPeriodViewController, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let timeRange = viewControllerToSync.timeRange
        guard !syncingTimeRanges.contains(timeRange) else {
            onCompletion?(.success(()))
            return
        }

        syncingTimeRanges.insert(timeRange)

        let group = DispatchGroup()

        var syncError: Error? = nil

        ensureGhostContentIsDisplayed(for: viewControllerToSync)

        defer {
            group.notify(queue: .main) { [weak self] in
                self?.syncingTimeRanges.remove(timeRange)
                if let error = syncError {
                    DDLogError("⛔️ Error loading dashboard: \(error)")
                    self?.handleSyncError(error: error)
                    onCompletion?(.failure(error))
                } else {
                    self?.updateSiteVisitors(mode: .default)
                    self?.trackDashboardStatsSyncComplete()
                    onCompletion?(.success(()))
                }
            }
        }

        // Since all stats charts are based on site time zone, we set the time zone for the stats UI and API requests using the site time zone.
        let timezoneForStatsDates = TimeZone.siteTimezone
        let timezoneForSync = TimeZone.siteTimezone

        [viewControllerToSync].forEach { [weak self] vc in
            guard let self = self else {
                onCompletion?(.success(()))
                return
            }

            if !forced, let lastFullSyncTimestamp = vc.lastFullSyncTimestamp, Date().timeIntervalSince(lastFullSyncTimestamp) < vc.minimalIntervalBetweenSync {
                // data refresh is not required
                onCompletion?(.success(()))
                return
            }

            // We want to make sure the latest data are fetched (force-refreshing the cache on the server side) when:
            // - The `forced` parameter is `true` (e.g. when the user pulls to refresh)
            // - The stats for the time range tab are being synced for the first time (`lastFullSyncTimestamp` is `nil`)
            let forceRefresh = forced || vc.lastFullSyncTimestamp == nil

            // local var to catch sync error for period
            var periodSyncError: Error? = nil

            vc.siteTimezone = timezoneForStatsDates

            let currentDate = Date()
            vc.currentDate = currentDate
            let latestDateToInclude = vc.timeRange.latestDate(currentDate: currentDate, siteTimezone: timezoneForSync)

            // For tasks dispatched for each time period.
            let periodGroup = DispatchGroup()

            // For tasks dispatched for store stats (order and visitor stats) for each time period.
            let periodStoreStatsGroup = DispatchGroup()

            group.enter()
            periodGroup.enter()
            periodStoreStatsGroup.enter()
            self.dashboardViewModel.syncStats(for: siteID,
                                              siteTimezone: timezoneForSync,
                                              timeRange: vc.timeRange,
                                              latestDateToInclude: latestDateToInclude,
                                              forceRefresh: forceRefresh) { [weak self] result in
                switch result {
                case .success:
                    self?.trackStatsLoaded(for: vc.timeRange)
                case .failure(let error):
                    DDLogError("⛔️ Error synchronizing order stats: \(error)")
                    periodSyncError = error
                }
                periodGroup.leave()
                periodStoreStatsGroup.leave()
                group.leave() // Leave this group last so `syncError` is set, if needed
            }

            group.enter()
            periodGroup.enter()
            periodStoreStatsGroup.enter()
            self.dashboardViewModel.syncSiteVisitStats(for: siteID,
                                                       siteTimezone: timezoneForSync,
                                                       timeRange: vc.timeRange,
                                                       latestDateToInclude: latestDateToInclude) { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
                    periodSyncError = error
                }
                periodGroup.leave()
                periodStoreStatsGroup.leave()
                group.leave() // Leave this group last so `syncError` is set, if needed
            }

            group.enter()
            periodGroup.enter()
            periodStoreStatsGroup.enter()
            self.dashboardViewModel.syncSiteSummaryStats(for: siteID,
                                                         siteTimezone: timezoneForSync,
                                                         timeRange: vc.timeRange,
                                                         latestDateToInclude: latestDateToInclude) { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error synchronizing summary stats: \(error)")
                    periodSyncError = error
                }
                periodGroup.leave()
                periodStoreStatsGroup.leave()
                group.leave() // Leave this group last so `syncError` is set, if needed
            }

            group.enter()
            periodGroup.enter()
            self.dashboardViewModel.syncTopEarnersStats(for: siteID,
                                                        siteTimezone: timezoneForSync,
                                                        timeRange: vc.timeRange,
                                                        latestDateToInclude: latestDateToInclude,
                                                        forceRefresh: forceRefresh) { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error synchronizing top earners stats: \(error)")
                    periodSyncError = error
                }
                periodGroup.leave()
                group.leave() // Leave this group last so `syncError` is set, if needed

                vc.removeTopPerformersGhostContent()
            }

            periodGroup.notify(queue: .main) {
                // Update last successful data sync timestamp
                if periodSyncError == nil {
                    vc.lastFullSyncTimestamp = Date()

                    // Reload the Store Info Widget after syncing the today's stats.
                    if vc.timeRange == .today {
                        WidgetCenter.shared.reloadTimelines(ofKind: WooConstants.storeInfoWidgetKind)
                    }
                } else {
                    syncError = periodSyncError
                }
            }

            periodStoreStatsGroup.notify(queue: .main) {
                vc.removeStoreStatsGhostContent()
            }
        }
    }

    func observeRemotelyCreatedOrdersToResetLastSyncTimestamp() {
        let siteID = self.siteID
        remoteOrdersSubscription = Publishers
            .Merge(pushNotificationsManager.backgroundNotifications, pushNotificationsManager.foregroundNotifications)
            .filter { $0.kind == .storeOrder && $0.siteID == siteID }
            .sink { [weak self] _ in
                self?.resetLastSyncTimestamp()
            }
    }

    func observeLocallyCreatedOrdersToResetLastSyncTimestamp() {
        let action = OrderAction.observeInsertedOrders(siteID: siteID) { [weak self] observableInsertedOrders in
            guard let self = self else { return }
            self.localOrdersSubscription = observableInsertedOrders
                .filter { $0.isNotEmpty }
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.resetLastSyncTimestamp()
                }
        }
        stores.dispatch(action)
    }

    func resetLastSyncTimestamp() {
        periodVCs.forEach { periodVC in
            periodVC.lastFullSyncTimestamp = nil
        }
    }
}

// MARK: - Placeholders
//
private extension StoreStatsAndTopPerformersViewController {

    /// Displays the Ghost Placeholder whenever there is no visible data.
    ///
    func ensureGhostContentIsDisplayed(for periodViewController: StoreStatsAndTopPerformersPeriodViewController) {
        guard periodViewController.shouldDisplayStoreStatsGhostContent else {
            return
        }
        periodViewController.displayGhostContent()
    }

    /// If the Ghost Content was previously onscreen, this method will restart the animations.
    ///
    func ensureGhostContentIsAnimated() {
        view.restartGhostAnimation(style: .wooDefaultGhostStyle)
    }
}


// MARK: - User Interface Configuration
//
private extension StoreStatsAndTopPerformersViewController {
    func createBorderView() -> UIView {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemColor(.separator)
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        return view
    }

    func configureView() {
        view.backgroundColor = Constants.backgroundColor
    }

    func configurePeriodViewControllers() {
        periodVCs.forEach { (vc) in
            vc.onPullToRefresh = { [weak self] in
                await self?.onPullToRefresh()
            }
        }
    }

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

    func configureTabBar() {
        tabBar.equalWidthFill = .equalSpacing
        tabBar.equalWidthSpacing = TabBar.tabSpacing

        if featureFlagService.isFeatureFlagEnabled(.customRangeInMyStoreAnalytics) {
            addCustomViewToTabBar(customRangeButtonView)
        }
    }

    @MainActor
    func configureCustomRangeTab() async {
        guard featureFlagService.isFeatureFlagEnabled(.customRangeInMyStoreAnalytics) else {
            return
        }

        guard let customRange = await loadTimeRangeForCustomRangeTab() else {
            return
        }

        createCustomRangeTab(range: customRange)
    }

    @MainActor
    func loadTimeRangeForCustomRangeTab() async -> StatsTimeRangeV4? {
        guard featureFlagService.isFeatureFlagEnabled(.customRangeInMyStoreAnalytics) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadCustomStatsTimeRange(siteID: siteID) { timeRange in
                continuation.resume(returning: timeRange)
            })
        }
    }

    func saveTimeRangeForCustomRangeTab(timeRange: StatsTimeRangeV4) {
        stores.dispatch(AppSettingsAction.setCustomStatsTimeRange(siteID: siteID, timeRange: timeRange))
    }

    func createCustomRangeButtonView() -> UIView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        let button = UIButton(configuration: .plain())
        button.setImage(UIImage(systemName: "calendar.badge.plus"), for: .normal)
        button.tintColor = .accent
        button.frame = CGRect(origin: .zero, size: TabBar.customRangeButtonSize)
        button.backgroundColor = .listForeground(modal: false)

        button.on(.touchUpInside) { [weak self] _ in
            self?.startCustomRangeTabCreation()
        }

        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: TabBar.customRangeViewSeparator).isActive = true
        separator.backgroundColor = .systemColor(.separator)

        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(separator)
        return stackView
    }

    func startCustomRangeTabCreation(startDate: Date? = nil, endDate: Date? = nil) {
        guard let navigationController else { return }
        customRangeCoordinator = CustomRangeTabCreationCoordinator(
            startDate: startDate,
            endDate: endDate,
            navigationController: navigationController,
            onDateRangeSelected: { [weak self] start, end in
                let range = StatsTimeRangeV4.custom(from: start, to: end)
                self?.saveTimeRangeForCustomRangeTab(timeRange: range)
                self?.createCustomRangeTab(range: range)
            }
        )
        customRangeCoordinator?.start()
    }

    func createCustomRangeTab(range: StatsTimeRangeV4) {
        let currentDate = Date()

        let customRangeVC = StoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                           timeRange: range,
                                                                           currentDate: currentDate,
                                                                           canDisplayInAppFeedbackCard: false,
                                                                           usageTracksEventEmitter: usageTracksEventEmitter,
                                                                           onEditCustomTimeRange: { [weak self] timeRange in
            guard case let .custom(startDate, endDate) = timeRange else {
                return
            }
            self?.startCustomRangeTabCreation(startDate: startDate, endDate: endDate)
        })

        // Custom range should not display visitors by default
        customRangeVC.siteVisitStatsMode = .redactedDueToCustomRange

        let customRangeTabbedItem = TabbedItem(title: range.tabTitle,
                                               viewController: customRangeVC,
                                               accessibilityIdentifier: "period-data-" + range.rawValue + "-tab")

        if let index = timeRanges.lastIndex(where: { $0.isCustomTimeRange }) {
            periodVCs[index] = customRangeVC
            timeRanges[index] = range
            replaceTab(at: index, with: customRangeTabbedItem)
        } else {
            periodVCs.append(customRangeVC)
            timeRanges.append(range)
            appendToTabBar(customRangeTabbedItem)
        }

        // Once a custom range tab is created, do not show the "Custom Range" button anymore.
        removeCustomViewFromTabBar()

        // Get stats data for this tab
        syncStats(forced: false, viewControllerToSync: customRangeVC)

        // Add pull to refresh functionality
        customRangeVC.onPullToRefresh = { [weak self] in
            await self?.onPullToRefresh()
        }
    }
}

private extension StoreStatsAndTopPerformersViewController {
    func updateSiteVisitors(mode: SiteVisitStatsMode) {
        periodVCs
            .filter { !$0.timeRange.isCustomTimeRange } // The Custom Range tab should always redact the visitor count.
            .forEach { vc in
                vc.siteVisitStatsMode = mode
            }
    }

    func handleSiteStatsStoreError(error: SiteStatsStoreError) {
        switch error {
        case .noPermission:
            updateSiteVisitors(mode: .hidden)
            trackDashboardStatsSyncComplete()
        case .statsModuleDisabled:
            let defaultSite = stores.sessionManager.defaultSite
            if defaultSite?.isJetpackCPConnected == true {
                updateSiteVisitors(mode: .redactedDueToJetpack)
            } else {
                updateSiteVisitors(mode: .hidden)
            }
            trackDashboardStatsSyncComplete()
        default:
            displaySyncingError(error)
            trackDashboardStatsSyncComplete(withError: error)
        }
    }

    private func handleSyncError(error: Error) {
        switch error {
        case let siteStatsStoreError as SiteStatsStoreError:
            handleSiteStatsStoreError(error: siteStatsStoreError)
        default:
            displaySyncingError(error)
            trackDashboardStatsSyncComplete(withError: error)
        }
    }
}

// MARK: - Private Helpers
//
private extension StoreStatsAndTopPerformersViewController {
    func trackStatsLoaded(for timeRange: StatsTimeRangeV4) {
        guard stores.isAuthenticated else {
            return
        }

        ServiceLocator.analytics.track(event: .Dashboard.dashboardMainStatsLoaded(timeRange: timeRange))
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

// MARK: - Constants!
//
private extension StoreStatsAndTopPerformersViewController {
    enum TabBar {
        /// With `equalSpacing` distribution, there is a default spacing ~16px even if `stackView.spacing = 0`.
        /// Setting a negative spacing offsets the default spacing to match the design more.
        static let tabSpacing: CGFloat = -8.0
        static let customRangeButtonSize = CGSize(width: 24, height: 24)
        static let customRangeViewSeparator: CGFloat = 0.5
    }

    enum Constants {
        static let backgroundColor: UIColor = .systemBackground
    }
}
