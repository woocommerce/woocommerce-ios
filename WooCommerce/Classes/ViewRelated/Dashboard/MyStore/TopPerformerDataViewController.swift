import UIKit
import Yosemite
import Charts
import XLPagerTabStrip
import CocoaLumberjack
import WordPressUI


class TopPerformerDataViewController: UIViewController, IndicatorInfoProvider {

    // MARK: - Properties

    public let granularity: StatGranularity

    @IBOutlet private weak var tableView: IntrinsicTableView!

    /// ResultsController: Loads TopEarnerStats for the current granularity from the Storage Layer
    ///
    private lazy var resultsController: ResultsController<StorageTopEarnerStats> = {
        let storageManager = AppDelegate.shared.storageManager
        let formattedDateString = StatsStore.buildDateString(from: Date(), with: granularity)
        let predicate = NSPredicate(format: "granularity = %@ AND date = %@", granularity.rawValue, formattedDateString)
        let descriptor = NSSortDescriptor(key: "date", ascending: true)

        return ResultsController<StorageTopEarnerStats>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    private var isInitialLoad: Bool = true  // Used in trackChangedTabIfNeeded()

    // MARK: - Computed Properties

    private var topEarnerStats: TopEarnerStats? {
        return resultsController.fetchedObjects.first
    }

    private var hasTopEarnerStatsItems: Bool {
        return (topEarnerStats?.items?.count ?? 0) > 0
    }

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
        configureResultsController()
        registerTableViewCells()
        registerTableViewHeaderFooters()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackChangedTabIfNeeded()
    }
}


// MARK: - Public Interface
//
extension TopPerformerDataViewController {

    func syncTopPerformers(onCompletion: (() -> Void)? = nil) {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            onCompletion?()
            return
        }

        let action = StatsAction.retrieveTopEarnerStats(siteID: siteID,
                                                        granularity: granularity,
                                                        latestDateToInclude: Date()) { [weak self] error in

            guard let `self` = self else {
                return
            }

            if let error = error {
                DDLogError("⛔️ Dashboard (Top Performers) — Error synchronizing top earner stats: \(error)")
            } else {
                WooAnalytics.shared.track(.dashboardTopPerformersLoaded, withProperties: ["granularity": self.granularity.rawValue])
            }
            onCompletion?()
        }

        StoresManager.shared.dispatch(action)
    }

    /// Renders Placeholder Content.
    /// Why is this public? Because the `syncTopPerformers` method is actually called from TopPerformersViewController.
    /// We coordinate multiple placeholder animations from that spot!
    ///
    func displayGhostContent() {
        let options = GhostOptions(reuseIdentifier: ProductTableViewCell.reuseIdentifier, rowsPerSection: Constants.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options)
    }

    /// Removes the Placeholder Content.
    /// Why is this public? Because the `syncTopPerformers` method is actually called from TopPerformersViewController.
    /// We coordinate multiple placeholder animations from that spot!
    ///
    func removeGhostContent() {
        tableView.removeGhostContent()
    }
}


// MARK: - Configuration
//
private extension TopPerformerDataViewController {

    func configureView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureTableView() {
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.separatorColor = StyleManager.cellSeparatorColor
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.estimatedSectionHeaderHeight = Constants.estimatedSectionHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = Constants.emptyView
    }

    func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.tableView.reloadData()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.tableView.reloadData()
        }
        try? resultsController.performFetch()
    }

    func registerTableViewCells() {
        let cells = [ProductTableViewCell.self, NoPeriodDataTableViewCell.self]

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
        return Constants.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows()
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
        guard let statsItem = statsItem(at: indexPath) else {
            return tableView.dequeueReusableCell(withIdentifier: NoPeriodDataTableViewCell.reuseIdentifier, for: indexPath)
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? ProductTableViewCell else {
            fatalError()
        }

        cell.configure(statsItem)
        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension TopPerformerDataViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
        return .leastNonzeroMagnitude
    }
}


// MARK: - Private Helpers
//
private extension TopPerformerDataViewController {

    func trackChangedTabIfNeeded() {
        // This is a little bit of a workaround to prevent the "tab tapped" tracks event from firing when launching the app.
        if granularity == .day && isInitialLoad {
            isInitialLoad = false
            return
        }
        WooAnalytics.shared.track(.dashboardTopPerformersDate, withProperties: ["range": granularity.rawValue])
        isInitialLoad = false
    }

    func statsItem(at indexPath: IndexPath) -> TopEarnerStatsItem? {
        guard let topEarnerStatsItem = topEarnerStats?.items?.sorted(by: >)[safe: indexPath.row] else {
            return nil
        }

        return topEarnerStatsItem
    }

    func numberOfRows() -> Int {
        guard hasTopEarnerStatsItems, let itemCount = topEarnerStats?.items?.count else {
            return Constants.emptyStateRowCount
        }
        return itemCount
    }
}


// MARK: - Constants!
//
private extension TopPerformerDataViewController {
    enum Text {
        static let sectionDescription = NSLocalizedString("Gain insights into how products are performing on your store", comment: "Description for Top Performers section of My Store tab.")
        static let sectionLeftColumn = NSLocalizedString("Product", comment: "Description for Top Performers left column header")
        static let sectionRightColumn = NSLocalizedString("Total Spend", comment: "Description for Top Performers right column header")
    }

    enum Constants {
        static let estimatedRowHeight           = CGFloat(80)
        static let estimatedSectionHeight       = CGFloat(125)
        static let numberOfSections             = 1
        static let emptyStateRowCount           = 1
        static let emptyView                    = UIView(frame: .zero)
        static let placeholderRowsPerSection    = [3]
    }
}
