import UIKit
import XLPagerTabStrip
import Yosemite

/// Top-level stats container view controller that consists of a button bar with 4 time ranges.
/// Each time range tab is managed by a `StoreStatsAndTopPerformersPeriodViewController`.
///
final class StoreStatsAndTopPerformersViewController: ButtonBarPagerTabStripViewController {
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
        return periodVCs[currentIndex]
    }

    // MARK: - Private Properties

    private var periodVCs = [StoreStatsAndTopPerformersPeriodViewController]()
    private let siteID: Int64
    private var isSyncing = false
    private let usageTracksEventEmitter = StoreStatsUsageTracksEventEmitter()
    private let dashboardViewModel: DashboardViewModel

    // MARK: - View Lifecycle

    init(siteID: Int64, dashboardViewModel: DashboardViewModel) {
        self.siteID = siteID
        self.dashboardViewModel = dashboardViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        configurePeriodViewControllers()
        configureTabStrip()
        // 👆 must be called before super.viewDidLoad()

        super.viewDidLoad()
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ensureGhostContentIsAnimated()
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return periodVCs
    }

    override func configureCell(_ cell: ButtonBarViewCell, indicatorInfo: IndicatorInfo) {
        /// Hide the ImageView:
        /// We don't use it, and if / when "Ghostified" produces a quite awful placeholder UI!
        cell.imageView.isHidden = true
        cell.accessibilityIdentifier = indicatorInfo.accessibilityIdentifier

        /// Flip the cells back to their proper state for RTL languages.
        if traitCollection.layoutDirection == .rightToLeft {
            cell.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }

    override func updateIndicator(for viewController: PagerTabStripViewController,
                                  fromIndex: Int,
                                  toIndex: Int,
                                  withProgressPercentage progressPercentage: CGFloat,
                                  indexWasChanged: Bool) {
        super.updateIndicator(for: viewController,
                              fromIndex: fromIndex,
                              toIndex: toIndex,
                              withProgressPercentage: progressPercentage,
                              indexWasChanged: indexWasChanged)
        guard fromIndex != toIndex, toIndex < periodVCs.count else {
            return
        }
        syncAllStats(forced: false)
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
    func syncAllStats(forced: Bool, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        guard !isSyncing else {
            return
        }

        isSyncing = true

        let group = DispatchGroup()

        var syncError: Error? = nil

        let viewControllerToSync = visibleChildViewController
        ensureGhostContentIsDisplayed(for: viewControllerToSync)
        showSpinner(for: viewControllerToSync, shouldShowSpinner: true)

        defer {
            group.notify(queue: .main) { [weak self] in
                self?.isSyncing = false
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
                return
            }

            if !forced, let lastFullSyncTimestamp = vc.lastFullSyncTimestamp, Date().timeIntervalSince(lastFullSyncTimestamp) < vc.minimalIntervalBetweenSync {
                // data refresh is not required
                return
            }

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
                                              latestDateToInclude: latestDateToInclude) { [weak self] result in
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
            self.dashboardViewModel.syncTopEarnersStats(for: siteID,
                                                        siteTimezone: timezoneForSync,
                                                        timeRange: vc.timeRange,
                                                        latestDateToInclude: latestDateToInclude) { result in
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

    func configureButtonBarBottomBorder() {
        view.addSubview(buttonBarBottomBorder)
        NSLayoutConstraint.activate([
            buttonBarBottomBorder.topAnchor.constraint(equalTo: buttonBarView.bottomAnchor),
            buttonBarBottomBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonBarBottomBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
    }

    func configureView() {
        view.backgroundColor = Constants.backgroundColor
        configureButtonBarBottomBorder()

        // Disables any content inset adjustment since `XLPagerTabStrip` doesn't seem to support safe area insets.
        containerView.contentInsetAdjustmentBehavior = .never

        /// ButtonBarView is a collection view, and it should flip to support
        /// RTL languages automatically. And yet it doesn't.
        /// So, for RTL languages, we flip it. This also flips the cells
        if traitCollection.layoutDirection == .rightToLeft {
            buttonBarView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }

    func configurePeriodViewControllers() {
        let currentDate = Date()
        let dayVC = StoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                   timeRange: .today,
                                                                   currentDate: currentDate,
                                                                   canDisplayInAppFeedbackCard: true,
                                                                   usageTracksEventEmitter: usageTracksEventEmitter)
        let weekVC = StoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                    timeRange: .thisWeek,
                                                                    currentDate: currentDate,
                                                                    canDisplayInAppFeedbackCard: false,
                                                                    usageTracksEventEmitter: usageTracksEventEmitter)
        let monthVC = StoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                     timeRange: .thisMonth,
                                                                     currentDate: currentDate,
                                                                     canDisplayInAppFeedbackCard: false,
                                                                     usageTracksEventEmitter: usageTracksEventEmitter)
        let yearVC = StoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                    timeRange: .thisYear,
                                                                    currentDate: currentDate,
                                                                    canDisplayInAppFeedbackCard: false,
                                                                    usageTracksEventEmitter: usageTracksEventEmitter)

        periodVCs.append(dayVC)
        periodVCs.append(weekVC)
        periodVCs.append(monthVC)
        periodVCs.append(yearVC)

        periodVCs.forEach { (vc) in
            vc.scrollDelegate = scrollDelegate
            vc.onPullToRefresh = { [weak self] in
                await self?.onPullToRefresh()
            }
        }
    }

    func configureTabStrip() {
        settings.style.buttonBarBackgroundColor = .systemColor(.secondarySystemGroupedBackground)
        settings.style.buttonBarItemBackgroundColor = .systemColor(.secondarySystemGroupedBackground)
        settings.style.selectedBarBackgroundColor = .primary
        settings.style.buttonBarItemFont = StyleManager.subheadlineFont
        settings.style.selectedBarHeight = TabStrip.selectedBarHeight
        settings.style.buttonBarItemTitleColor = .textSubtle
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarItemLeftRightMargin = TabStrip.buttonLeftRightMargin

        changeCurrentIndexProgressive = {
            (oldCell: ButtonBarViewCell?,
            newCell: ButtonBarViewCell?,
            progressPercentage: CGFloat,
            changeCurrentIndex: Bool,
            animated: Bool) -> Void in

            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .textSubtle
            newCell?.label.textColor = .primary
        }
    }
}

private extension StoreStatsAndTopPerformersViewController {
    func updateSiteVisitors(mode: SiteVisitStatsMode) {
        periodVCs.forEach { vc in
            vc.siteVisitStatsMode = mode
        }
    }

    func handleSiteVisitStatsStoreError(error: SiteVisitStatsStoreError) {
        switch error {
        case .noPermission:
            updateSiteVisitors(mode: .hidden)
        case .statsModuleDisabled:
            let defaultSite = ServiceLocator.stores.sessionManager.defaultSite
            let jcpFeatureFlagEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.jetpackConnectionPackageSupport)
            if defaultSite?.isJetpackCPConnected == true, jcpFeatureFlagEnabled {
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
        case let siteVisitStatsStoreError as SiteVisitStatsStoreError:
            handleSiteVisitStatsStoreError(error: siteVisitStatsStoreError)
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
    enum TabStrip {
        static let buttonLeftRightMargin: CGFloat   = 16.0
        static let selectedBarHeight: CGFloat       = 3.0
    }

    enum Constants {
        static let backgroundColor: UIColor = .systemBackground
    }
}
