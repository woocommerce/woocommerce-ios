import UIKit
import Yosemite
import Charts
import XLPagerTabStrip
import CocoaLumberjack


class TopPerformerDataViewController: UIViewController, IndicatorInfoProvider {

    // MARK: - Properties

    public let granularity: StatGranularity

    @IBOutlet private weak var tableView: UITableView!

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
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
    }
}


// MARK: - User Interface Configuration
//
private extension TopPerformerDataViewController {

    func configureView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureTableView() {
        tableView.backgroundColor = StyleManager.wooWhite
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = Settings.estimatedRowHeight
        tableView.estimatedSectionHeaderHeight = Settings.estimatedSectionHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    func registerTableViewCells() {
        let cells = [LeftImageTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    func registerTableViewHeaderFooters() {
        let headersAndFooters = [TopPerformersHeaderView.self]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}


// MARK: - IndicatorInfoProvider Conformance (Tab Bar)
//
extension TopPerformerDataViewController {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: tabDescription)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension TopPerformerDataViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
        // FIXME: Make this work!
        //return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
        // FIXME: Make this work!
        //return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: TopPerformersHeaderView.reuseIdentifier) as? TopPerformersHeaderView else {
            fatalError()
        }

        cell.configure(descriptionText: Text.sectionDescription,
                       leftText: Text.sectionLeftColumn.uppercased(),
                       rightText: Text.sectionRightColumn.uppercased())
        return cell
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LeftImageTableViewCell.reuseIdentifier, for: indexPath) as? LeftImageTableViewCell else {
            fatalError()
        }

        return cell

        // FIXME: Make this work!
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension TopPerformerDataViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}


// MARK: - Constants!
//
private extension TopPerformerDataViewController {
    enum Text {
        static let noActivity = NSLocalizedString("No activity this period", comment: "Default text for Top Performers section when no data exists for a given period.")
        static let sectionDescription = NSLocalizedString("Gain insights into how products are performing on your store", comment: "Description for Top Performers section of My Store tab.")
        static let sectionLeftColumn = NSLocalizedString("Product", comment: "Description for Top Performers left column header")
        static let sectionRightColumn = NSLocalizedString("Total Spend", comment: "Description for Top Performers right column header")
    }

    enum Settings {
        static let estimatedRowHeight = CGFloat(64)
        static let estimatedSectionHeight = CGFloat(125)
    }
}

