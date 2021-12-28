import UIKit
import XLPagerTabStrip
import Yosemite

/// Top-level stats container view controller that consists of a button bar with 4 time ranges.
/// Each time range tab is managed by a `OldStoreStatsAndTopPerformersViewController`.
///
final class OldStoreStatsAndTopPerformersViewController: ButtonBarPagerTabStripViewController {
    /// For navigation bar large title workaround.
    weak var scrollDelegate: DashboardUIScrollDelegate?

    // MARK: - DashboardUI protocol

    var displaySyncingError: () -> Void = {}

    var onPullToRefresh: () -> Void = {}

    // MARK: - Subviews

    private lazy var buttonBarBottomBorder: UIView = {
        return createBorderView()
    }()

    // MARK: - Calculated Properties

    private var visibleChildViewController: OldStoreStatsAndTopPerformersPeriodViewController {
        return periodVCs[currentIndex]
    }

    // MARK: - Private Properties

    private var periodVCs = [OldStoreStatsAndTopPerformersPeriodViewController]()
    private let siteID: Int64
    private var isSyncing = false

    // MARK: - View Lifecycle

    init(siteID: Int64) {
        self.siteID = siteID
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
}

extension OldStoreStatsAndTopPerformersViewController: DashboardUI {
    func reloadData(forced: Bool, completion: @escaping () -> Void) {
        syncAllStats(forced: forced, onCompletion: { _ in
            completion()
        })
    }

    func remindStatsUpgradeLater() {
        // No op as this VC represents the latest stats version to date.
    }
}

// MARK: - Syncing Data
//
private extension OldStoreStatsAndTopPerformersViewController {
    func syncAllStats(forced: Bool, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        guard !isSyncing else {
            return
        }

        isSyncing = true

        let group = DispatchGroup()

        var syncError: Error? = nil

        ensureGhostContentIsDisplayed()
        showSpinner(shouldShowSpinner: true)

        defer {
            group.notify(queue: .main) { [weak self] in
                self?.isSyncing = false
                self?.removeGhostContent()
                self?.showSpinner(shouldShowSpinner: false)
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

        periodVCs.forEach { [weak self] (vc) in
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

            group.enter()
            periodGroup.enter()
            self.syncStats(for: siteID,
                           siteTimezone: timezoneForSync,
                           timeRange: vc.timeRange,
                           latestDateToInclude: latestDateToInclude) { [weak self] result in
                switch result {
                case .success:
                    self?.trackStatsLoaded(for: vc.granularity)
                case .failure(let error):
                    DDLogError("⛔️ Error synchronizing order stats: \(error)")
                    periodSyncError = error
                }
                group.leave()
                periodGroup.leave()
            }

            group.enter()
            periodGroup.enter()
            self.syncSiteVisitStats(for: siteID,
                                    siteTimezone: timezoneForSync,
                                    timeRange: vc.timeRange,
                                    latestDateToInclude: latestDateToInclude) { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
                    periodSyncError = error
                }
                group.leave()
                periodGroup.leave()
            }

            group.enter()
            periodGroup.enter()
            self.syncTopEarnersStats(for: siteID,
                                     siteTimezone: timezoneForSync,
                                     timeRange: vc.timeRange,
                                     latestDateToInclude: latestDateToInclude) { result in
                if case let .failure(error) = result {
                    DDLogError("⛔️ Error synchronizing top earners stats: \(error)")
                    periodSyncError = error
                }
                group.leave()
                periodGroup.leave()
            }

            periodGroup.notify(queue: .main) {
                // Update last successful data sync timestamp
                if periodSyncError == nil {
                    vc.lastFullSyncTimestamp = Date()
                } else {
                    syncError = periodSyncError
                }
            }
        }
    }

    func showSpinner(shouldShowSpinner: Bool) {
        periodVCs.forEach { (vc) in
            if shouldShowSpinner {
                vc.refreshControl.beginRefreshing()
            } else {
                vc.refreshControl.endRefreshing()
            }
        }
    }
}

// MARK: - Placeholders
//
private extension OldStoreStatsAndTopPerformersViewController {

    /// Displays the Ghost Placeholder whenever there is no visible data.
    ///
    func ensureGhostContentIsDisplayed() {
        guard visibleChildViewController.shouldDisplayStoreStatsGhostContent else {
            return
        }

        displayGhostContent()
    }

    /// Locks UI Interaction and displays Ghost Placeholder animations.
    ///
    func displayGhostContent() {
        view.isUserInteractionEnabled = false
        buttonBarView.startGhostAnimation(style: .wooDefaultGhostStyle)
        visibleChildViewController.displayGhostContent()
    }

    /// Unlocks the and removes the Placeholder Content
    ///
    func removeGhostContent() {
        view.isUserInteractionEnabled = true
        buttonBarView.stopGhostAnimation()
        visibleChildViewController.removeGhostContent()
    }

    /// If the Ghost Content was previously onscreen, this method will restart the animations.
    ///
    func ensureGhostContentIsAnimated() {
        view.restartGhostAnimation(style: .wooDefaultGhostStyle)
    }
}


// MARK: - User Interface Configuration
//
private extension OldStoreStatsAndTopPerformersViewController {
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
        view.backgroundColor = .listBackground
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
        let dayVC = OldStoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                   timeRange: .today,
                                                                   currentDate: currentDate,
                                                                   canDisplayInAppFeedbackCard: true)
        let weekVC = OldStoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                    timeRange: .thisWeek,
                                                                    currentDate: currentDate,
                                                                    canDisplayInAppFeedbackCard: false)
        let monthVC = OldStoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                     timeRange: .thisMonth,
                                                                     currentDate: currentDate,
                                                                     canDisplayInAppFeedbackCard: false)
        let yearVC = OldStoreStatsAndTopPerformersPeriodViewController(siteID: siteID,
                                                                    timeRange: .thisYear,
                                                                    currentDate: currentDate,
                                                                    canDisplayInAppFeedbackCard: false)

        periodVCs.append(dayVC)
        periodVCs.append(weekVC)
        periodVCs.append(monthVC)
        periodVCs.append(yearVC)

        periodVCs.forEach { (vc) in
            vc.scrollDelegate = scrollDelegate
            vc.onPullToRefresh = { [weak self] in
                self?.onPullToRefresh()
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

// MARK: - Sync'ing Helpers
//
private extension OldStoreStatsAndTopPerformersViewController {
    func syncStats(for siteID: Int64,
                   siteTimezone: TimeZone,
                   timeRange: StatsTimeRangeV4,
                   latestDateToInclude: Date,
                   onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        let action = StatsActionV4.retrieveStats(siteID: siteID,
                                                 timeRange: timeRange,
                                                 earliestDateToInclude: earliestDateToInclude,
                                                 latestDateToInclude: latestDateToInclude,
                                                 quantity: timeRange.maxNumberOfIntervals,
                                                 onCompletion: { result in
                                                    if case let .failure(error) = result {
                                                        DDLogError("⛔️ Dashboard (Order Stats) — Error synchronizing order stats v4: \(error)")
                                                    }
                                                    onCompletion?(result)
        })

        ServiceLocator.stores.dispatch(action)
    }

    func syncSiteVisitStats(for siteID: Int64,
                            siteTimezone: TimeZone,
                            timeRange: StatsTimeRangeV4,
                            latestDateToInclude: Date,
                            onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let action = StatsActionV4.retrieveSiteVisitStats(siteID: siteID,
                                                          siteTimezone: siteTimezone,
                                                          timeRange: timeRange,
                                                          latestDateToInclude: latestDateToInclude,
                                                          onCompletion: { result in
                                                            if case let .failure(error) = result {
                                                                DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
                                                            }
                                                            onCompletion?(result)
        })

        ServiceLocator.stores.dispatch(action)
    }

    func syncTopEarnersStats(for siteID: Int64,
                             siteTimezone: TimeZone,
                             timeRange: StatsTimeRangeV4,
                             latestDateToInclude: Date,
                             onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        let action = StatsActionV4.retrieveTopEarnerStats(siteID: siteID,
                                                          timeRange: timeRange,
                                                          earliestDateToInclude: earliestDateToInclude,
                                                          latestDateToInclude: latestDateToInclude,
                                                          onCompletion: { result in
                                                            switch result {
                                                            case .success:
                                                                ServiceLocator.analytics.track(.dashboardTopPerformersLoaded,
                                                                                               withProperties: [
                                                                                                "granularity": timeRange.topEarnerStatsGranularity.rawValue
                                                                                               ])
                                                            case .failure(let error):
                                                                DDLogError("⛔️ Dashboard (Top Performers) — Error synchronizing top earner stats: \(error)")
                                                            }
                                                            onCompletion?(result)
        })

        ServiceLocator.stores.dispatch(action)
    }
}

private extension OldStoreStatsAndTopPerformersViewController {
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
private extension OldStoreStatsAndTopPerformersViewController {
    func trackStatsLoaded(for granularity: StatsGranularityV4) {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }

        ServiceLocator.analytics.track(.dashboardMainStatsLoaded, withProperties: ["granularity": granularity.rawValue])
    }
}

// MARK: - Constants!
//
private extension OldStoreStatsAndTopPerformersViewController {
    enum TabStrip {
        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}
