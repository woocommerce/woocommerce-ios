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

    public var isDataMissing: Bool {
        return (periodVCs.contains { $0.orderStats == nil }) ||
            (periodVCs.contains { $0.siteStats == nil })
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

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return periodVCs
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

    func syncAllStats() {
        clearAllFields()
        periodVCs.forEach { (vc) in
            syncOrderStats(for: vc.granularity)
            syncVisitorStats(for: vc.granularity)
        }
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

        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = StyleManager.defaultTextColor
            newCell?.label.textColor = StyleManager.wooCommerceBrandColor
        }
    }
}


// MARK: - Sync'ing Helpers
//
private extension StoreStatsViewController {

    func syncVisitorStats(for granularity: StatGranularity, onCompletion: ((Error?) -> ())? = nil) {
        // FIXME: This is really just WIP code which puts data in the fields. Refactor please.
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            onCompletion?(nil)
            return
        }

        let action = StatsAction.retrieveSiteVisitStats(siteID: siteID,
                                                        granularity: granularity,
                                                        latestDateToInclude: Date(),
                                                        quantity: quantity(for: granularity)) { [weak self] (siteVisitStats, error) in
            guard let `self` = self, let siteVisitStats = siteVisitStats else {
                DDLogError("⛔️ Error synchronizing site visit stats: \(error.debugDescription)")
                onCompletion?(error)
                return
            }

            let vc = self.periodDataVC(for: granularity)
            vc?.siteStats = siteVisitStats
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func syncOrderStats(for granularity: StatGranularity, onCompletion: ((Error?) -> ())? = nil) {
        // FIXME: This is really just WIP code which puts data in the fields. Refactor please.
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            onCompletion?(nil)
            return
        }

        let action = StatsAction.retrieveOrderStats(siteID: siteID,
                                                    granularity: granularity,
                                                    latestDateToInclude: Date(),
                                                    quantity: quantity(for: granularity)) { [weak self] (orderStats, error) in
            guard let `self` = self, let orderStats = orderStats else {
                DDLogError("⛔️ Error synchronizing order stats: \(error.debugDescription)")
                onCompletion?(error)
                return
            }

            let vc = self.periodDataVC(for: granularity)
            vc?.orderStats = orderStats
            WooAnalytics.shared.track(.dashboardMainStatsLoaded, withProperties: ["granularity": granularity.rawValue])
            onCompletion?(nil)
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
