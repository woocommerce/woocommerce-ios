import UIKit
import Yosemite
import XLPagerTabStrip
import CocoaLumberjack


class PeriodDataViewController: UIViewController, IndicatorInfoProvider {

    // MARK: Properties

    @IBOutlet private weak var visitorsTitle: UILabel!
    @IBOutlet private weak var visitorsData: UILabel!
    @IBOutlet private weak var ordersTitle: UILabel!
    @IBOutlet private weak var ordersData: UILabel!
    @IBOutlet private weak var revenueTitle: UILabel!
    @IBOutlet private weak var revenueData: UILabel!
    @IBOutlet private weak var lastUpdated: UILabel!
    @IBOutlet private weak var chartView: UIView!
    @IBOutlet private weak var borderView: UIView!
    
    private var tabTitle: String = ""

    /// Designated Initializer
    ///
    init(tabTitle: String) {
        self.tabTitle = tabTitle
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder Conformance
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: View Lifecycle

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
        lastUpdated.textColor = StyleManager.wooGreyMid
    }
}
