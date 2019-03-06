import UIKit
import Yosemite
import CocoaLumberjack
import XLPagerTabStrip


class StoreStatsViewController: ButtonBarPagerTabStripViewController {

    // MARK: - Properties

    @IBOutlet private weak var topBorder: UIView!
    @IBOutlet private weak var middleBorder: UIView!
    @IBOutlet private weak var bottomBorder: UIView!

    private var periodVCs = [PeriodDataViewController]()


    // MARK: - Calculated Properties

    private var visibleChildViewController: PeriodDataViewController {
        return periodVCs[currentIndex]
    }


    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
    }
}


// MARK: - Public Interface
//
extension StoreStatsViewController {
    func clearAllFields() {
        periodVCs.forEach { (vc) in
            vc.clearAllFields()
        }
    }

    func syncAllStats(onCompletion: ((Error?) -> Void)? = nil) {
        let group = DispatchGroup()

        var syncError: Error? = nil

        ensureGhostContentIsDisplayed()

        periodVCs.forEach { (vc) in
            group.enter()

            syncOrderStats(for: vc.granularity) { error in
                if let error = error {
                    DDLogError("⛔️ Error synchronizing order stats: \(error)")
                    syncError = error
                } else {
                    WooAnalytics.shared.track(.dashboardMainStatsLoaded, withProperties: ["granularity": vc.granularity.rawValue])
                }
                group.leave()
            }

            group.enter()
            syncVisitorStats(for: vc.granularity) { error in
                if let error = error {
                    DDLogError("⛔️ Error synchronizing visitor stats: \(error)")
                    syncError = error
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
private extension StoreStatsViewController {

    /// Displays the Ghost Placeholder whenever there is no visible data.
    ///
    func ensureGhostContentIsDisplayed() {
        guard visibleChildViewController.shouldDisplayGhostContent else {
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
private extension StoreStatsViewController {

    func configureView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        topBorder.backgroundColor = StyleManager.wooGreyBorder
        middleBorder.backgroundColor = StyleManager.wooGreyBorder
        bottomBorder.backgroundColor = StyleManager.wooGreyBorder
    }

    func configurePeriodViewControllers() {
        let dayVC = PeriodDataViewController(granularity: .day)
        let weekVC = PeriodDataViewController(granularity: .week)
        let monthVC = PeriodDataViewController(granularity: .month)
        let yearVC = PeriodDataViewController(granularity: .year)

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
private extension StoreStatsViewController {

    func syncVisitorStats(for granularity: StatGranularity, onCompletion: ((Error?) -> Void)? = nil) {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            DDLogWarn("⚠️ Tried to sync order stats without a current defaultStoreID")
            onCompletion?(nil)
            return
        }

        let action = StatsAction.retrieveSiteVisitStats(siteID: siteID,
                                                        granularity: granularity,
                                                        latestDateToInclude: Date(),
                                                        quantity: quantity(for: granularity)) { (error) in
            if let error = error {
                DDLogError("⛔️ Dashboard (Site Stats) — Error synchronizing site visit stats: \(error)")
            }
            onCompletion?(error)
        }
        StoresManager.shared.dispatch(action)
    }

    func syncOrderStats(for granularity: StatGranularity, onCompletion: ((Error?) -> Void)? = nil) {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            DDLogWarn("⚠️ Tried to sync order stats without a current defaultStoreID")
            onCompletion?(nil)
            return
        }

        let action = StatsAction.retrieveOrderStats(siteID: siteID,
                                                    granularity: granularity,
                                                    latestDateToInclude: Date(),
                                                    quantity: quantity(for: granularity)) { (error) in
            if let error = error {
                DDLogError("⛔️ Dashboard (Order Stats) — Error synchronizing order stats: \(error)")
            }
            onCompletion?(error)
        }
        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Private Helpers
//
private extension StoreStatsViewController {

    func periodDataVC(for granularity: StatGranularity) -> PeriodDataViewController? {
        return periodVCs.filter({ $0.granularity == granularity }).first
    }

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
}


// MARK: - Constants!
//
private extension StoreStatsViewController {
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
