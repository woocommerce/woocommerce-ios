import UIKit
import Yosemite
import DGCharts
import Experiments
import SwiftUI
import WordPressUI
import class AutomatticTracks.CrashLogging
import protocol Storage.StorageManagerType

final class TopPerformerDataViewController: UIViewController {

    // MARK: - Properties

    var siteTimeZone: TimeZone = .current {
        didSet {
            updateResultsController(siteTimeZone: siteTimeZone)
        }
    }

    private let timeRange: StatsTimeRangeV4
    private let granularity: StatGranularity
    private let siteID: Int64
    private let currentDate: Date

    /// ResultsController: Loads TopEarnerStats for the current granularity from the Storage Layer
    ///
    private var resultsController: ResultsController<StorageTopEarnerStats>?

    private var isInitialLoad: Bool = true  // Used in trackChangedTabIfNeeded()

    private var hostingController: UIHostingController<TopPerformersPeriodView>?

    private let imageService: ImageService = ServiceLocator.imageService

    private let storageManager: StorageManagerType
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    private lazy var viewModel = TopPerformersPeriodViewModel(state: .loading(cached: [])) { [weak self] topPerformersItem in
        guard let self else { return }
        self.usageTracksEventEmitter.interacted()
        self.presentProductDetails(statsItem: topPerformersItem)
    }

    // MARK: - Computed Properties

    private var topEarnerStats: TopEarnerStats? {
        resultsController?.fetchedObjects.first
    }

    // MARK: - Initialization

    /// Designated Initializer
    ///
    init(siteID: Int64,
         siteTimeZone: TimeZone,
         currentDate: Date,
         timeRange: StatsTimeRangeV4,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        self.siteID = siteID
        self.siteTimeZone = siteTimeZone
        self.currentDate = currentDate
        self.granularity = timeRange.topEarnerStatsGranularity
        self.timeRange = timeRange
        self.storageManager = storageManager
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
        updateResultsController(siteTimeZone: siteTimeZone)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackChangedTabIfNeeded()
    }

    func displayPlaceholderContent() {
        updateUIInLoadingState()
    }

    func removePlaceholderContent() {
        updateUIInLoadedState()
    }
}

private extension TopPerformerDataViewController {
    func updateUIInLoadingState() {
        viewModel.update(state: .loading(cached: []))
        if #unavailable(iOS 16.0) {
            hostingController?.view.invalidateIntrinsicContentSize()
        }
    }

    func updateUIInLoadedState() {
        defer {
            if #unavailable(iOS 16.0) {
                hostingController?.view.invalidateIntrinsicContentSize()
            }
        }
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
        let hostingController = SelfSizingHostingController(rootView: TopPerformersPeriodView(viewModel: viewModel))
        self.hostingController = hostingController
        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(hostingController.view)
        hostingController.didMove(toParent: self)

        updateUIInLoadingState()
    }

    func updateResultsController(siteTimeZone: TimeZone) {
        let resultsController = createResultsController(siteTimeZone: siteTimeZone)
        self.resultsController = resultsController
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

    func createResultsController(siteTimeZone: TimeZone) -> ResultsController<StorageTopEarnerStats> {
        let formattedDateString: String = {
            let date = timeRange.latestDate(currentDate: currentDate, siteTimezone: siteTimeZone)
            return StatsStoreV4.buildDateString(from: date, timeRange: timeRange)
        }()
        let predicate = NSPredicate(format: "granularity = %@ AND date = %@ AND siteID = %ld", granularity.rawValue, formattedDateString, siteID)
        let descriptor = NSSortDescriptor(key: "date", ascending: true)

        return ResultsController<StorageTopEarnerStats>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
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
