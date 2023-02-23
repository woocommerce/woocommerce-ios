import Combine
import UIKit
import Yosemite
import class WidgetKit.WidgetCenter

/// Top-level stats container view controller that consists of a button bar with 4 time ranges.
/// Each time range tab is managed by a `StoreStatsAndTopPerformersPeriodViewController`.
///
final class StoreStatsAndTopPerformersViewController: TabbedViewController {
    /// For navigation bar large title workaround.
    weak var scrollDelegate: DashboardUIScrollDelegate?

    // MARK: - DashboardUI protocol

    var displaySyncingError: () -> Void = {}

    var onPullToRefresh: @MainActor () async -> Void = {}

    // MARK: - Subviews

    private lazy var buttonBarBottomBorder: UIView = {
        return createBorderView()
    }()

    // MARK: - Calculated Properties

    private var visibleChildViewController: StoreStatsAndTopPerformersPeriodViewController {
        return periodVCs[selection]
    }

    // MARK: - Private Properties

    private let periodVCs: [StoreStatsAndTopPerformersPeriodViewController]
    private let siteID: Int64
    // A set of syncing time ranges is tracked instead of a single boolean so that the stats for each time range
    // can be synced when swiping or tapping to change the time range tab before the syncing finishes for the previously selected tab.
    private var syncingTimeRanges: Set<StatsTimeRangeV4> = []
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter
    private let dashboardViewModel: DashboardViewModel
    private let timeRanges: [StatsTimeRangeV4] = [.today, .thisWeek, .thisMonth, .thisYear]

    /// Because loading the last selected time range tab is async, the selected tab index is initially `nil` and set after the last selected value is loaded.
    /// We need to make sure any call to the public `reloadData` is after the selected time range is set to avoid making unnecessary API requests
    /// for the non-selected tab.
    @Published private var selectedTimeRangeIndex: Int? {
        didSet {
            guard let selectedTimeRangeIndex, oldValue != selectedTimeRangeIndex else {
                return
            }
            selection = selectedTimeRangeIndex
        }
    }
    override var selection: Int {
        didSet {
            selectedTimeRangeIndex = selection
        }
    }
    private var selectedTimeRangeIndexSubscription: AnyCancellable?
    private var reloadDataAfterSelectedTimeRangeSubscriptions: Set<AnyCancellable> = []

    private let pushNotificationsManager: PushNotesManager
    private var localOrdersSubscription: AnyCancellable?
    private var remoteOrdersSubscription: AnyCancellable?

    // MARK: - View Lifecycle

    init(siteID: Int64,
         dashboardViewModel: DashboardViewModel,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.siteID = siteID
        self.dashboardViewModel = dashboardViewModel
        self.pushNotificationsManager = pushNotificationsManager

        let usageTracksEventEmitter = StoreStatsUsageTracksEventEmitter()
        self.usageTracksEventEmitter = usageTracksEventEmitter

        let currentDate = Date()
        let tabItems: [TabbedItem] = timeRanges.map { timeRange in
            let viewController = StoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                                timeRange: timeRange,
                                                                                currentDate: currentDate,
                                                                                canDisplayInAppFeedbackCard: timeRange == .today,
                                                                                usageTracksEventEmitter: usageTracksEventEmitter)
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

        Task { @MainActor in
            let selectedTimeRange = await loadLastTimeRange() ?? .today
            guard let selectedTabIndex = timeRanges.firstIndex(of: selectedTimeRange),
                  selectedTabIndex != selection else {
                selectedTimeRangeIndex = selection
                return
            }
            selectedTimeRangeIndex = selectedTabIndex
        }

        configureView()
        configureTabBar()
        configurePeriodViewControllers()
        observeSelectedTimeRangeIndex()
        observeRemotelyCreatedOrdersToResetLastSyncTimestamp()
        observeLocallyCreatedOrdersToResetLastSyncTimestamp()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ensureGhostContentIsAnimated()
    }

    func observeSelectedTimeRangeIndex() {
        let timeRangeCount = timeRanges.count
        selectedTimeRangeIndexSubscription = $selectedTimeRangeIndex
            .compactMap { $0 }
            // It's possible to reach an out-of-bound index by swipe gesture, thus checking the index range here.
            .filter { $0 >= 0 && $0 < timeRangeCount }
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
}

extension StoreStatsAndTopPerformersViewController: DashboardUI {
    @MainActor
    func reloadData(forced: Bool) async {
        await withCheckedContinuation { continuation in
            $selectedTimeRangeIndex
                .compactMap { $0 }
                .first()
                .sink { [weak self] _ in
                    self?.syncAllStats(forced: forced) { _ in
                        continuation.resume(returning: ())
                    }
                }
                .store(in: &reloadDataAfterSelectedTimeRangeSubscriptions)
        }
    }

    func remindStatsUpgradeLater() {
        // No op as this VC represents the latest stats version to date.
    }
}

// MARK: - Syncing Data
//
private extension StoreStatsAndTopPerformersViewController {
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
        showSpinner(for: viewControllerToSync, shouldShowSpinner: true)

        defer {
            group.notify(queue: .main) { [weak self] in
                self?.syncingTimeRanges.remove(timeRange)
                self?.showSpinner(for: viewControllerToSync, shouldShowSpinner: false)
                if let error = syncError {
                    DDLogError("⛔️ Error loading dashboard: \(error)")
                    self?.handleSyncError(error: error)
                    onCompletion?(.failure(error))
                } else {
                    self?.updateSiteVisitors(mode: .default)
                    onCompletion?(.success(()))
                }
            }
        }

        // Since the stats charts are based on site time zone, we set the time zone for the stats UI to be the site time zone.
        // On the other hand, when syncing the stats data with the API, we want to use the device time zone to find the time range since the API date parameters
        // have no time zone information and are relative to the site time zone (e.g. 12:00am-11:59pm for "Today" tab).
        let timezoneForStatsDates = TimeZone.siteTimezone
        let timezoneForSync = TimeZone.current

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
                group.leave()
                periodGroup.leave()
                periodStoreStatsGroup.leave()
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
                group.leave()
                periodGroup.leave()
                periodStoreStatsGroup.leave()
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
                group.leave()
                periodGroup.leave()
                periodStoreStatsGroup.leave()
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
                group.leave()
                periodGroup.leave()

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

    func showSpinner(for periodViewController: StoreStatsAndTopPerformersPeriodViewController, shouldShowSpinner: Bool) {
        if shouldShowSpinner {
            periodViewController.refreshControl.beginRefreshing()
        } else {
            periodViewController.refreshControl.endRefreshing()
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
        ServiceLocator.stores.dispatch(action)
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
            vc.scrollDelegate = scrollDelegate
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
            ServiceLocator.stores.dispatch(action)
        }
    }

    func saveLastTimeRange(_ timeRange: StatsTimeRangeV4) {
        let action = AppSettingsAction.setLastSelectedStatsTimeRange(siteID: siteID, timeRange: timeRange)
        ServiceLocator.stores.dispatch(action)
    }

    func configureTabBar() {
        tabBar.equalWidthFill = .equalSpacing
        tabBar.equalWidthSpacing = TabBar.tabSpacing
    }
}

private extension StoreStatsAndTopPerformersViewController {
    func updateSiteVisitors(mode: SiteVisitStatsMode) {
        periodVCs.forEach { vc in
            vc.siteVisitStatsMode = mode
        }
    }

    func handleSiteStatsStoreError(error: SiteStatsStoreError) {
        switch error {
        case .noPermission:
            updateSiteVisitors(mode: .hidden)
        case .statsModuleDisabled:
            let defaultSite = ServiceLocator.stores.sessionManager.defaultSite
            if defaultSite?.isJetpackCPConnected == true {
                updateSiteVisitors(mode: .redactedDueToJetpack)
            } else {
                updateSiteVisitors(mode: .hidden)
            }
        default:
            displaySyncingError()
        }
    }

    private func handleSyncError(error: Error) {
        switch error {
        case let siteStatsStoreError as SiteStatsStoreError:
            handleSiteStatsStoreError(error: siteStatsStoreError)
        default:
            displaySyncingError()
        }
    }
}

// MARK: - Private Helpers
//
private extension StoreStatsAndTopPerformersViewController {
    func trackStatsLoaded(for timeRange: StatsTimeRangeV4) {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }

        ServiceLocator.analytics.track(event: .Dashboard.dashboardMainStatsLoaded(timeRange: timeRange))
    }
}

// MARK: - Constants!
//
private extension StoreStatsAndTopPerformersViewController {
    enum TabBar {
        /// With `equalSpacing` distribution, there is a default spacing ~16px even if `stackView.spacing = 0`.
        /// Setting a negative spacing offsets the default spacing to match the design more.
        static let tabSpacing: CGFloat = -8.0
    }

    enum Constants {
        static let backgroundColor: UIColor = .systemBackground
    }
}
