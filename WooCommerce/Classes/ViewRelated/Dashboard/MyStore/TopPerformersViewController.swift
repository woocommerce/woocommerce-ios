import UIKit
import Yosemite
import CocoaLumberjack
import XLPagerTabStrip


class TopPerformersViewController: ButtonBarPagerTabStripViewController {

    // MARK: - Properties

    @IBOutlet private weak var topBorder: UIView!
    @IBOutlet private weak var middleBorder: UIView!
    @IBOutlet private weak var bottomBorder: UIView!

    private var dataVCs = [TopPerformerDataViewController]()

    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        configureDataViewControllers()
        configureTabStrip()
        // 👆 must be called before super.viewDidLoad()

        super.viewDidLoad()
        configureView()
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return dataVCs
    }
}


// MARK: - Public Interface
//
extension TopPerformersViewController {

    func syncTopPerformers() {
        dataVCs.forEach { (vc) in
            syncTopPerformers(for: vc.granularity)
        }
    }
}


// MARK: - User Interface Configuration
//
private extension TopPerformersViewController {

    func configureView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        topBorder.backgroundColor = StyleManager.wooGreyBorder
        middleBorder.backgroundColor = StyleManager.wooGreyBorder
        bottomBorder.backgroundColor = StyleManager.wooGreyBorder
    }

    func configureDataViewControllers() {
        let dayVC = TopPerformerDataViewController(granularity: .day)
        let weekVC = TopPerformerDataViewController(granularity: .week)
        let monthVC = TopPerformerDataViewController(granularity: .month)
        let yearVC = TopPerformerDataViewController(granularity: .year)

        dataVCs.append(dayVC)
        dataVCs.append(weekVC)
        dataVCs.append(monthVC)
        dataVCs.append(yearVC)
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
private extension TopPerformersViewController {

    func syncTopPerformers(for granularity: StatGranularity, onCompletion: ((Error?) -> ())? = nil) {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            onCompletion?(nil)
            return
        }

        let action = StatsAction.retrieveTopEarnerStats(siteID: siteID, granularity: granularity, latestDateToInclude: Date()) { (error) in
            if let error = error {
                DDLogError("⛔️ Dashboard (Top Performers) — Error synchronizing top earner stats: \(error)")
            }
        }

        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Constants!
//
private extension TopPerformersViewController {
    enum TabStrip {
        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}

