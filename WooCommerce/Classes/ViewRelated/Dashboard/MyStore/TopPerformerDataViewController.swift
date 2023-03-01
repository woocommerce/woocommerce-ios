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

    private lazy var viewModel = DashboardTopPerformersViewModel(state: .loading) { [weak self] topPerformersItem in
        guard let self else { return }
        self.usageTracksEventEmitter.interacted()
        self.presentProductDetails(statsItem: topPerformersItem)
    }

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
        configureTopPerformersView()
        configureResultsController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackChangedTabIfNeeded()
    }

    func displayPlaceholderContent() {
        viewModel.update(state: .loading)
    }

    func removePlaceholderContent() {
        updateUIInLoadedState()
    }
}

private extension TopPerformerDataViewController {
    func updateUIInLoadedState() {
        guard let items = topEarnerStats?.items?.sorted(by: >), items.isNotEmpty else {
            return viewModel.update(state: .loaded(rows: []))
        }
        viewModel.update(state: .loaded(rows: items))
    }
}


// MARK: - Configuration
//
private extension TopPerformerDataViewController {
    func configureView() {
        view.backgroundColor = .basicBackground
    }

    func configureTopPerformersView() {
        let hostingController = ConstraintsUpdatingHostingController(rootView: DashboardTopPerformersView(viewModel: viewModel))
        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(hostingController.view)
        hostingController.didMove(toParent: self)

        viewModel.update(state: .loading)
    }

    func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateUIInLoadedState()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateUIInLoadedState()
        }

        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
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
