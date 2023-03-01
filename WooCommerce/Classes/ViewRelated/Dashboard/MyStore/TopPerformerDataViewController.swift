import UIKit
import Yosemite
import Charts
import Experiments
import SwiftUI
import WordPressUI
import class AutomatticTracks.CrashLogging



final class TopPerformerDataViewController: UIViewController {

    // MARK: - Properties

    private let timeRange: StatsTimeRangeV4
    private let granularity: StatGranularity
    private let siteID: Int64
    private let siteTimeZone: TimeZone
    private let currentDate: Date

    var hasTopEarnerStatsItems: Bool {
        return (topEarnerStats?.items?.count ?? 0) > 0
    }

    /// ResultsController: Loads TopEarnerStats for the current granularity from the Storage Layer
    ///
    private lazy var resultsController: ResultsController<StorageTopEarnerStats> = {
        let storageManager = ServiceLocator.storageManager
        let formattedDateString: String = {
            let date = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimeZone)
            return StatsStoreV4.buildDateString(from: date, with: granularity)
        }()
        let predicate = NSPredicate(format: "granularity = %@ AND date = %@ AND siteID = %ld", granularity.rawValue, formattedDateString, siteID)
        let descriptor = NSSortDescriptor(key: "date", ascending: true)

        return ResultsController<StorageTopEarnerStats>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    private var isInitialLoad: Bool = true  // Used in trackChangedTabIfNeeded()

    private let imageService: ImageService = ServiceLocator.imageService

    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    // MARK: - Computed Properties

    private var topEarnerStats: TopEarnerStats? {
        return resultsController.fetchedObjects.first
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
    init(siteID: Int64,
         siteTimeZone: TimeZone,
         currentDate: Date,
         timeRange: StatsTimeRangeV4,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        self.siteID = siteID
        self.siteTimeZone = siteTimeZone
        self.currentDate = currentDate
        self.granularity = timeRange.topEarnerStatsGranularity
        self.timeRange = timeRange
        self.usageTracksEventEmitter = usageTracksEventEmitter
        super.init(nibName: nil, bundle: nil)
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
        showTopPerformers(items: [], isLoading: true)
        configureResultsController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackChangedTabIfNeeded()
    }
}

private extension TopPerformerDataViewController {
    func updateUI() {
        guard let items = topEarnerStats?.items, items.isNotEmpty else {
            // todo-jc: show empty view
            showEmptyView()
            return
        }
        showTopPerformers(items: items, isLoading: false)
    }

    func showTopPerformers(items: [TopEarnerStatsItem], isLoading: Bool) {
        view.subviews.forEach { subview in
            subview.removeFromSuperview()
        }

        let rows = items.map { item in
            TopPerformersRow.Data(imageURL: URL(string: item.imageUrl ?? ""),
                                  name: item.productName ?? "",
                                  details: AnalyticsHubViewModel.Localization.ProductCard.netSales(value: item.totalString),
                                  value: "\(item.quantity)")
        }
        let hostingController = ConstraintsUpdatingHostingController(rootView: TopPerformersView(itemTitle: "ITEM", valueTitle: "VALUE", rows: rows, isRedacted: isLoading, showsHeader: false))

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    func showEmptyView() {
        view.subviews.forEach { subview in
            subview.removeFromSuperview()
        }

        // TODO-JC
    }
}


// MARK: - Configuration
//
private extension TopPerformerDataViewController {

    func configureView() {
        view.backgroundColor = .basicBackground
    }

    func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateUI()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateUI()
        }

        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
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
        nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let statsItem = statsItem(at: indexPath) else {
            return tableView.dequeueReusableCell(withIdentifier: NoPeriodDataTableViewCell.reuseIdentifier, for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(ProductTableViewCell.self, for: indexPath)
        let viewModel = ProductTableViewCell.ViewModel(statsItem: statsItem)
        cell.configure(viewModel: viewModel, imageService: imageService)
        cell.hidesBottomBorder = tableView.lastIndexPathOfTheLastSection() == indexPath ? true : false
        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension TopPerformerDataViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let statsItem = statsItem(at: indexPath) else {
            return
        }

        usageTracksEventEmitter.interacted()

        presentProductDetails(statsItem: statsItem)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0
    }
}

// MARK: Navigation Actions
//

private extension TopPerformerDataViewController {

    /// Presents the product details for a given TopEarnerStatsItem.
    ///
    func presentProductDetails(statsItem: TopEarnerStatsItem) {
        let loaderViewController = ProductLoaderViewController(model: .init(topEarnerStatsItem: statsItem),
                                                               siteID: siteID,
                                                               forceReadOnly: false)
        let navController = WooNavigationController(rootViewController: loaderViewController)
        present(navController, animated: true, completion: nil)
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
        ServiceLocator.analytics.track(event: .Dashboard.dashboardTopPerformersDate(timeRange: timeRange))
        isInitialLoad = false
    }

    func statsItem(at indexPath: IndexPath) -> TopEarnerStatsItem? {
        guard let topEarnerStatsItem = topEarnerStats?.items?
                .sorted(by: >)[safe: indexPath.row] else {
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
    enum TableViewStyle {
        static let backgroundColor = UIColor.basicBackground
        static let separatorColor = UIColor.systemColor(.separator)
    }

    enum Constants {
        static let estimatedRowHeight           = CGFloat(80)
        static let estimatedSectionHeight       = CGFloat(125)
        static let numberOfSections             = 1
        static let emptyStateRowCount           = 1
        static let placeholderRowsPerSection    = [3]
        static let sectionHeaderTopSpacing = CGFloat(0)
    }
}
