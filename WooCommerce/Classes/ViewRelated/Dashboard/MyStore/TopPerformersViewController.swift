import UIKit
import Yosemite
import CocoaLumberjack
import XLPagerTabStrip


class TopPerformersViewController: ButtonBarPagerTabStripViewController {

    // MARK: - Properties

    @IBOutlet private weak var topBorder: UIView!
    @IBOutlet private weak var middleBorder: UIView!
    @IBOutlet private weak var headingLabel: PaddedLabel!

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
            vc.syncTopPerformers()
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
        headingLabel.applyFootnoteStyle()
        headingLabel.textColor = StyleManager.sectionTitleColor
        headingLabel.textInsets = Constants.headerLabelInsets
        headingLabel.text =  NSLocalizedString("Top Performers", comment: "Header label for Top Performers section of My Store tab.").uppercased()
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


// MARK: - Constants!
//
private extension TopPerformersViewController {
    enum Constants {
        static let headerLabelInsets = UIEdgeInsets(top: 0, left: 14, bottom: 6, right: 14)
    }

    enum TabStrip {
        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}

