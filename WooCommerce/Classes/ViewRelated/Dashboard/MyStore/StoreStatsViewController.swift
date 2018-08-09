import UIKit
import XLPagerTabStrip


// MARK: - MyStoreStatsViewController
//
class StoreStatsViewController: ButtonBarPagerTabStripViewController {

    // MARK: Properties

    @IBOutlet weak var topBorder: UIView!
    @IBOutlet weak var middleBorder: UIView!
    @IBOutlet weak var bottomBorder: UIView!

    // MARK: View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        configureTabStrip() // 👈 must be called before super.viewDidLoad()
        super.viewDidLoad()

        configureView()
    }

    // MARK: PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {

        let child_1 = PeriodDataViewController()
        child_1.view.backgroundColor = StyleManager.statusSuccessColor
        child_1.tabTitle = TabStrip.titleDay
        let child_2 = PeriodDataViewController()
        child_2.view.backgroundColor = StyleManager.statusDangerColor
        child_2.tabTitle = TabStrip.titleWeek
        let child_3 = PeriodDataViewController()
        child_3.view.backgroundColor = StyleManager.statusNotIdentifiedBoldColor
        child_3.tabTitle = TabStrip.titleMonth
        let child_4 = PeriodDataViewController()
        child_4.view.backgroundColor = StyleManager.statusPrimaryBoldColor
        child_4.tabTitle = TabStrip.titleYear

        return [child_1, child_2, child_3, child_4]
    }
}


// MARK: - User Interface Initialization
//
private extension StoreStatsViewController {

    func configureView() {
        topBorder.backgroundColor = StyleManager.wooGreyBorder
        middleBorder.backgroundColor = StyleManager.wooGreyBorder
        bottomBorder.backgroundColor = StyleManager.wooGreyBorder
    }

    func configureTabStrip() {
        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.selectedBarBackgroundColor = StyleManager.wooCommerceBrandColor
        settings.style.buttonBarItemFont = StyleManager.subheadlineFont
        settings.style.selectedBarHeight = TabStrip.selectedBarHeight
        settings.style.buttonBarItemTitleColor = StyleManager.wooGreyTextMin
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarItemLeftRightMargin = TabStrip.buttonLeftRightMargin

        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = StyleManager.wooGreyTextMin
            newCell?.label.textColor = StyleManager.wooCommerceBrandColor
        }
    }
}


// MARK: - Constants!
//
private extension StoreStatsViewController {
    enum TabStrip {
        static let titleDay     = NSLocalizedString("Days", comment: "Title of stats tab for a specific period — plural form of day.")
        static let titleWeek    = NSLocalizedString("Weeks", comment: "Title of stats tab for a specific period — plural form of week.")
        static let titleMonth   = NSLocalizedString("Months", comment: "Title of stats tab for a specific period — plural form of month.")
        static let titleYear    = NSLocalizedString("Years", comment: "Title of stats tab for a specific period — plural form of year.")

        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}
