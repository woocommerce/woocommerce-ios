import UIKit
import Yosemite
import Charts
import XLPagerTabStrip
import CocoaLumberjack


class TopPerformerDataViewController: UIViewController, IndicatorInfoProvider {

    // MARK: - Properties

    public let granularity: StatGranularity

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var descriptionLabel: PaddedLabel!
    @IBOutlet private weak var borderView: UIView!

    // MARK: - Computed Properties

    private var tabDescription: String {
        switch granularity {
        case .day:
            return NSLocalizedString("Today", comment: "Top Performers section title - today")
        case .week:
            return NSLocalizedString("This Week", comment: "Top Performers section title - this week")
        case .month:
            return NSLocalizedString("This Month", comment: "Top Performers section title - this month")
        case .year:
            return NSLocalizedString("This Year", comment: "Top Performers section title - this year")
        }
    }

    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(granularity: StatGranularity) {
        self.granularity = granularity
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder Conformance
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadAllFields()
    }
}


// MARK: - User Interface Configuration
//
private extension TopPerformerDataViewController {

    func configureView() {
        view.backgroundColor = StyleManager.wooWhite
        borderView.backgroundColor = StyleManager.wooGreyBorder
        descriptionLabel.applyBodyStyle()
        descriptionLabel.textInsets = Constants.descriptionLabelInsets
        descriptionLabel.text =  NSLocalizedString("Gain insights into how products are performing on your store", comment: "Description for Top Performers section of My Store tab.")
    }
}


// MARK: - IndicatorInfoProvider Conformance (Tab Bar)
//
extension TopPerformerDataViewController {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: tabDescription)
    }
}


// MARK: - Private Helpers
//
private extension TopPerformerDataViewController {

    func reloadAllFields() {
        // TODO: fill this in!
    }
}


// MARK: - Constants!
//
private extension TopPerformerDataViewController {
    enum Constants {
        static let descriptionLabelInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        static let noActivityText = NSLocalizedString("No activity this period", comment: "Default text for Top Performers section when no data exists for a given period.")
    }
}

