import UIKit
import XLPagerTabStrip
import Yosemite

/// Top-level stats container view controller that consists of a button bar with 4 time ranges.
/// Each time range tab is managed by a `StoreStatsAndTopPerformersPeriodViewController`.
///
class StoreStatsAndTopPerformersViewController: ButtonBarPagerTabStripViewController {

    // MARK: - DashboardUI protocol

    var displaySyncingErrorNotice: () -> Void = {}

    var onPullToRefresh: () -> Void = {}

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

    // MARK: - View Lifecycle

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

    // MARK: - RTL support

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        /// ButtonBarView is a collection view, and it should flip to support
        /// RTL languages automatically. And yet it doesn't.
        /// So, for RTL languages, we flip it. This also flips the cells
        if traitCollection.layoutDirection == .rightToLeft {
            buttonBarView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return periodVCs
    }

    override func configureCell(_ cell: ButtonBarViewCell, indicatorInfo: IndicatorInfo) {
        /// Hide the ImageView:
        /// We don't use it, and if / when "Ghostified" produces a quite awful placeholder UI!
        cell.imageView.isHidden = true

        /// Flip the cells back to their proper state for RTL languages.
        if traitCollection.layoutDirection == .rightToLeft {
            cell.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }
}

extension StoreStatsAndTopPerformersViewController: DashboardUI {
    func defaultAccountDidUpdate() {
        clearAllFields()
    }

    func reloadData(completion: @escaping () -> Void) {
        syncAllStats { _ in
            completion()
        }
    }
}

// MARK: - Syncing Data
//
private extension StoreStatsAndTopPerformersViewController {
    func syncAllStats(onCompletion: ((Error?) -> Void)? = nil) {
        let group = DispatchGroup()

        var syncError: Error? = nil

        ensureGhostContentIsDisplayed()

        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        showSpinner(shouldShowSpinner: true)

        defer {
            group.notify(queue: .main) { [weak self] in
                self?.removeGhostContent()
                self?.showSpinner(shouldShowSpinner: false)
                if let error = syncError {
                    DDLogError("⛔️ Error loading dashboard: \(error)")
                    self?.handleSyncError(error: error)
                } else {
                    self?.showSiteVisitors(true)
                }
                onCompletion?(syncError)
            }
        }

        // When the site time zone can be correctly fetched, and also supports the Stats v4 API, consider using the site time zone
        // for stats UI (#1375).
        let timezoneForStatsDates = TimeZone.current

        periodVCs.forEach { (vc) in
            vc.siteTimezone = timezoneForStatsDates

            let currentDate = Date()
            vc.currentDate = currentDate
            let latestDateToInclude = vc.timeRange.latestDate(currentDate: currentDate, siteTimezone: timezoneForStatsDates)

            group.enter()
            self.syncStats(for: siteID,
                           siteTimezone: timezoneForStatsDates,
                           timeRange: vc.timeRange,
                           latestDateToInclude: latestDateToInclude) { [weak self] error in
                if let error = error {
                    DDLogError("⛔️ Error synchronizing order stats: \(error)")
                    syncError = error
                } else {
                    self?.trackStatsLoaded(for: vc.granularity)
                }
                group.leave()
            }

            group.enter()
            self.syncSiteVisitStats(for: siteID,
                                    siteTimezone: timezoneForStatsDates,
                                    timeRange: vc.timeRange,
                                    latestDateToInclude: latestDateToInclude) { error in
                if let error = error {
                    DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
                    syncError = error
                }
                group.leave()
            }

            group.enter()
            self.syncTopEarnersStats(for: siteID,
                                     timeRange: vc.timeRange,
                                     latestDateToInclude: latestDateToInclude) { error in
                if let error = error {
                    DDLogError("⛔️ Error synchronizing top earners stats: \(error)")
                    syncError = error
                }
                group.leave()
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
private extension StoreStatsAndTopPerformersViewController {

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
private extension StoreStatsAndTopPerformersViewController {
    func createBorderView() -> UIView {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .listSmallIcon
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 1)
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
    }

    func configurePeriodViewControllers() {
        let currentDate = Date()
        let dayVC = StoreStatsAndTopPerformersPeriodViewController(timeRange: .today, currentDate: currentDate)
        let weekVC = StoreStatsAndTopPerformersPeriodViewController(timeRange: .thisWeek, currentDate: currentDate)
        let monthVC = StoreStatsAndTopPerformersPeriodViewController(timeRange: .thisMonth, currentDate: currentDate)
        let yearVC = StoreStatsAndTopPerformersPeriodViewController(timeRange: .thisYear, currentDate: currentDate)

        periodVCs.append(dayVC)
        periodVCs.append(weekVC)
        periodVCs.append(monthVC)
        periodVCs.append(yearVC)

        periodVCs.forEach { (vc) in
            vc.onPullToRefresh = { [weak self] in
                self?.onPullToRefresh()
            }
        }
    }

    func configureTabStrip() {
        settings.style.buttonBarBackgroundColor = .basicBackground
        settings.style.buttonBarItemBackgroundColor = .basicBackground
        settings.style.selectedBarBackgroundColor = .brand
        settings.style.buttonBarItemFont = StyleManager.subheadlineFont
        settings.style.selectedBarHeight = TabStrip.selectedBarHeight
        settings.style.buttonBarItemTitleColor = .text
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarItemLeftRightMargin = TabStrip.buttonLeftRightMargin

        changeCurrentIndexProgressive = {
            (oldCell: ButtonBarViewCell?,
            newCell: ButtonBarViewCell?,
            progressPercentage: CGFloat,
            changeCurrentIndex: Bool,
            animated: Bool) -> Void in

            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .text
            newCell?.label.textColor = .brand
        }
    }
}

// MARK: - Sync'ing Helpers
//
private extension StoreStatsAndTopPerformersViewController {
    func syncStats(for siteID: Int,
                   siteTimezone: TimeZone,
                   timeRange: StatsTimeRangeV4,
                   latestDateToInclude: Date,
                   onCompletion: ((Error?) -> Void)? = nil) {
        let earliestDateToInclude = timeRange.earliestDate(latestDate: latestDateToInclude, siteTimezone: siteTimezone)
        let action = StatsActionV4.retrieveStats(siteID: siteID,
                                                 timeRange: timeRange,
                                                 earliestDateToInclude: earliestDateToInclude,
                                                 latestDateToInclude: latestDateToInclude,
                                                 quantity: timeRange.maxNumberOfIntervals,
                                                 onCompletion: { error in
                                                    if let error = error {
                                                        DDLogError("⛔️ Dashboard (Order Stats) — Error synchronizing order stats v4: \(error)")
                                                    }
                                                    onCompletion?(error)
        })

        ServiceLocator.stores.dispatch(action)
    }

    func syncSiteVisitStats(for siteID: Int,
                            siteTimezone: TimeZone,
                            timeRange: StatsTimeRangeV4,
                            latestDateToInclude: Date,
                            onCompletion: ((Error?) -> Void)? = nil) {
        let action = StatsActionV4.retrieveSiteVisitStats(siteID: siteID,
                                                          siteTimezone: siteTimezone,
                                                          timeRange: timeRange,
                                                          latestDateToInclude: latestDateToInclude) { error in
                                                            if let error = error {
                                                                DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
                                                            }
                                                            onCompletion?(error)
        }

        ServiceLocator.stores.dispatch(action)
    }

    func syncTopEarnersStats(for siteID: Int, timeRange: StatsTimeRangeV4, latestDateToInclude: Date, onCompletion: ((Error?) -> Void)? = nil) {
        let action = StatsActionV4.retrieveTopEarnerStats(siteID: siteID,
                                                          timeRange: timeRange,
                                                          latestDateToInclude: Date()) { error in
                                                            if let error = error {
                                                                DDLogError("⛔️ Dashboard (Top Performers) — Error synchronizing top earner stats: \(error)")
                                                            } else {
                                                                ServiceLocator.analytics.track(.dashboardTopPerformersLoaded,
                                                                                          withProperties: [
                                                                                            "granularity": timeRange.topEarnerStatsGranularity.rawValue
                                                                    ])
                                                            }
                                                            onCompletion?(error)
        }

        ServiceLocator.stores.dispatch(action)
    }
}

private extension StoreStatsAndTopPerformersViewController {
    func clearAllFields() {
        periodVCs.forEach { (vc) in
            vc.clearAllFields()
        }
    }

    func showSiteVisitors(_ shouldShowSiteVisitors: Bool) {
        periodVCs.forEach { vc in
            vc.shouldShowSiteVisitStats = shouldShowSiteVisitors
        }
    }

    func handleSiteVisitStatsStoreError(error: SiteVisitStatsStoreError) {
        switch error {
        case .statsModuleDisabled, .noPermission:
            showSiteVisitors(false)
        default:
            displaySyncingErrorNotice()
        }
    }

    private func handleSyncError(error: Error) {
        switch error {
        case let siteVisitStatsStoreError as SiteVisitStatsStoreError:
            handleSiteVisitStatsStoreError(error: siteVisitStatsStoreError)
        default:
            displaySyncingErrorNotice()
        }
    }
}

// MARK: - Private Helpers
//
private extension StoreStatsAndTopPerformersViewController {
    func trackStatsLoaded(for granularity: StatsGranularityV4) {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }

        ServiceLocator.analytics.track(.dashboardMainStatsLoaded, withProperties: ["granularity": granularity.rawValue])
    }
}

// MARK: - Constants!
//
private extension StoreStatsAndTopPerformersViewController {
    enum TabStrip {
        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}
