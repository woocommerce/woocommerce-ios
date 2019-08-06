import UIKit
import XLPagerTabStrip
import Yosemite

class StoreStatsAndTopPerformersViewController: ButtonBarPagerTabStripViewController {

    var displaySyncingErrorNotice: () -> Void = {}

    var onPullToRefresh: () -> Void = {}

    private var periodVCs = [StoreStatsAndTopPerformersPeriodViewController]()

    // MARK: - Calculated Properties

    private var visibleChildViewController: StoreStatsAndTopPerformersPeriodViewController {
        return periodVCs[currentIndex]
    }

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

    /// Note: Overrides this function to always trigger `updateContent()` to ensure the child view controller fills the container width.
    /// This is probably only an issue when not using `ButtonBarPagerTabStripViewController` with Storyboard.
    override func updateIfNeeded() {
        updateContent()
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

    }

    func reloadData(completion: @escaping () -> Void) {
        syncAllStats { _ in
            completion()
        }
    }
}

// MARK: - Public Interface
//
extension StoreStatsAndTopPerformersViewController {
    func clearAllFields() {
        periodVCs.forEach { (vc) in
            vc.clearAllFields()
        }
    }

    func updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: Bool) {
        for periodVC in periodVCs {
            periodVC.shouldShowSiteVisitStats = shouldShowSiteVisitStats
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

        periodVCs.forEach { (vc) in
            let latestDateToInclude = Date()

            group.enter()
            syncStats(for: vc.timeRange, latestDateToInclude: latestDateToInclude) { [weak self] error in
                if let error = error {
                    DDLogError("⛔️ Error synchronizing order stats: \(error)")
                    syncError = error
                } else {
                    self?.trackStatsLoaded(for: vc.granularity)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.removeGhostContent()
            onCompletion?(syncError)
        }
    }
}

// MARK: - Placeholders
//
private extension StoreStatsAndTopPerformersViewController {

    /// Displays the Ghost Placeholder whenever there is no visible data.
    ///
    func ensureGhostContentIsDisplayed() {
        // TODO: rename to store stats
        guard visibleChildViewController.shouldDisplayStoreStatsGhostContent else {
            return
        }

        displayGhostContent()
    }

    /// Locks UI Interaction and displays Ghost Placeholder animations.
    ///
    func displayGhostContent() {
        view.isUserInteractionEnabled = false
        buttonBarView.startGhostAnimation()
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
        view.restartGhostAnimation()
    }
}


// MARK: - User Interface Configuration
//
private extension StoreStatsAndTopPerformersViewController {

    func configureView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        // TODO: add borders
//        topBorder.backgroundColor = StyleManager.wooGreyBorder
//        middleBorder.backgroundColor = StyleManager.wooGreyBorder
//        bottomBorder.backgroundColor = StyleManager.wooGreyBorder
    }

    func configurePeriodViewControllers() {
        let dayVC = StoreStatsAndTopPerformersPeriodViewController(timeRange: .today)
        let weekVC = StoreStatsAndTopPerformersPeriodViewController(timeRange: .thisWeek)
        let monthVC = StoreStatsAndTopPerformersPeriodViewController(timeRange: .thisMonth)
        let yearVC = StoreStatsAndTopPerformersPeriodViewController(timeRange: .thisYear)

        periodVCs.append(dayVC)
        periodVCs.append(weekVC)
        periodVCs.append(monthVC)
        periodVCs.append(yearVC)
    }

    func configureTabStrip() {
        settings.style.buttonBarBackgroundColor = StyleManager.wooWhite
        settings.style.buttonBarItemBackgroundColor = StyleManager.wooWhite
        settings.style.selectedBarBackgroundColor = StyleManager.wooCommerceBrandColor
        settings.style.buttonBarItemFont = StyleManager.subheadlineFont
        settings.style.selectedBarHeight = TabStrip.selectedBarHeight
        settings.style.buttonBarItemTitleColor = StyleManager.defaultTextColor
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarItemLeftRightMargin = TabStrip.buttonLeftRightMargin

        changeCurrentIndexProgressive = {
            (oldCell: ButtonBarViewCell?,
            newCell: ButtonBarViewCell?,
            progressPercentage: CGFloat,
            changeCurrentIndex: Bool,
            animated: Bool) -> Void in

            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = StyleManager.defaultTextColor
            newCell?.label.textColor = StyleManager.wooCommerceBrandColor
        }
    }
}

// MARK: - Sync'ing Helpers
//
private extension StoreStatsAndTopPerformersViewController {
    func syncStats(for timeRange: StatsTimeRangeV4, latestDateToInclude: Date, onCompletion: ((Error?) -> Void)? = nil) {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            onCompletion?(nil)
            return
        }

        let action = StatsActionV4.retrieveStats(siteID: siteID,
                                                 timeRange: timeRange,
                                                 earliestDateToInclude: timeRange.earliestDate(latestDate: latestDateToInclude),
                                                 latestDateToInclude: latestDateToInclude,
                                                 quantity: timeRange.intervalQuantity,
                                                 onCompletion: { error in
                                                    if let error = error {
                                                        DDLogError("⛔️ Dashboard (Order Stats) — Error synchronizing order stats v4: \(error)")
                                                    }
                                                    onCompletion?(error)
        })

        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Private Helpers
//
private extension StoreStatsAndTopPerformersViewController {
    func quantity(for granularity: StatGranularity) -> Int {
        switch granularity {
        case .day:
            return Constants.quantityDefaultForDay
        case .week:
            return Constants.quantityDefaultForWeek
        case .month:
            return Constants.quantityDefaultForMonth
        case .year:
            return Constants.quantityDefaultForYear
        }
    }

    func trackStatsLoaded(for granularity: StatsGranularityV4) {
        guard StoresManager.shared.isAuthenticated else {
            return
        }

        WooAnalytics.shared.track(.dashboardMainStatsLoaded, withProperties: ["granularity": granularity.rawValue])
    }
}


// MARK: - Constants!
//
private extension StoreStatsAndTopPerformersViewController {
    enum Constants {
        static let quantityDefaultForDay = 30
        static let quantityDefaultForWeek = 13
        static let quantityDefaultForMonth = 12
        static let quantityDefaultForYear = 5
    }

    enum TabStrip {
        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}
