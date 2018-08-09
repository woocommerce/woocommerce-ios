import UIKit
import Yosemite
import XLPagerTabStrip


class PeriodDataViewController: UIViewController, IndicatorInfoProvider {

    @IBOutlet weak var visitorsTitle: UILabel!
    @IBOutlet weak var visitorsData: UILabel!
    @IBOutlet weak var ordersTitle: UILabel!
    @IBOutlet weak var ordersData: UILabel!
    @IBOutlet weak var revenueTitle: UILabel!
    @IBOutlet weak var revenueData: UILabel!
    @IBOutlet weak var lastUpdated: UILabel!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var borderView: UIView!
    
    var tabTitle: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
}


// MARK: - IndicatorInfoProvider Confromance
//
extension PeriodDataViewController {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: tabTitle)
    }
}


// MARK: - User Interface Initialization
//
private extension PeriodDataViewController {

    func configureView() {
        view.backgroundColor = .white
        borderView.backgroundColor = StyleManager.wooGreyBorder

        // Titles
        visitorsTitle.applyFootnoteStyle()
        ordersTitle.applyFootnoteStyle()
        revenueTitle.applyFootnoteStyle()

        // Data
        visitorsData.font = StyleManager.statsBigDataFont
        visitorsData.textColor = StyleManager.defaultTextColor
        ordersData.font = StyleManager.statsBigDataFont
        ordersData.textColor = StyleManager.defaultTextColor
        revenueData.font = StyleManager.statsBigDataFont
        revenueData.textColor = StyleManager.defaultTextColor

        // Footer
        lastUpdated.font = UIFont.footnote
        lastUpdated.textColor = StyleManager.wooGreyTextMin
    }
}
