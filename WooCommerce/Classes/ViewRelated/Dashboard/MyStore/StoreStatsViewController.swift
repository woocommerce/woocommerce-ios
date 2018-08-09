import UIKit
import XLPagerTabStrip


// MARK: - MyStoreStatsViewController
//
class StoreStatsViewController: ButtonBarPagerTabStripViewController {

    // MARK: View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        // This 👇 must be called before super.viewDidLoad()
        configureTabStrip()

        super.viewDidLoad()
    }

    // MARK: PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {

        let child_1 = PeriodDataViewController()
        child_1.view.backgroundColor = StyleManager.statusSuccessColor
        child_1.tabTitle = Tabs.titleDay
        let child_2 = PeriodDataViewController()
        child_2.view.backgroundColor = StyleManager.statusDangerColor
        child_2.tabTitle = Tabs.titleWeek
        let child_3 = PeriodDataViewController()
        child_3.view.backgroundColor = StyleManager.statusNotIdentifiedBoldColor
        child_3.tabTitle = Tabs.titleMonth
        let child_4 = PeriodDataViewController()
        child_4.view.backgroundColor = StyleManager.statusPrimaryBoldColor
        child_4.tabTitle = Tabs.titleYear

        return [child_1, child_2, child_3, child_4]
    }
}


// MARK: - User Interface Initialization
//
private extension StoreStatsViewController {

    func configureTabStrip() {
        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.selectedBarBackgroundColor = StyleManager.wooCommerceBrandColor
        settings.style.buttonBarItemFont = .headline
        settings.style.selectedBarHeight = 2.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = StyleManager.wooGreyMid
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
        settings.style.buttonBarItemLeftRightMargin = 12.0

        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = StyleManager.wooGreyMid
            newCell?.label.textColor = StyleManager.wooCommerceBrandColor
        }
    }
}

// MARK: - Constants!
//
private extension StoreStatsViewController {
    enum Tabs {
        static let titleDay = NSLocalizedString("Days", comment: "Title of stats tab for a specific period — plural form of day.")
        static let titleWeek = NSLocalizedString("Weeks", comment: "Title of stats tab for a specific period — plural form of week.")
        static let titleMonth = NSLocalizedString("Months", comment: "Title of stats tab for a specific period — plural form of month.")
        static let titleYear = NSLocalizedString("Years", comment: "Title of stats tab for a specific period — plural form of year.")
    }
}
