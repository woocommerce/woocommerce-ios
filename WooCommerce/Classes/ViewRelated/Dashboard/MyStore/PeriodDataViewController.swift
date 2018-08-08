import UIKit
import Yosemite
import XLPagerTabStrip


class PeriodDataViewController: UIViewController, IndicatorInfoProvider {

    var tabTitle: String = "1"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }
}


// MARK: - IndicatorInfoProvider Confromance
//
extension PeriodDataViewController {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: tabTitle)
    }
}
