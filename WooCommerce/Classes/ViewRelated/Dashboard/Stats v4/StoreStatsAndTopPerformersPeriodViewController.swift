import Combine
import UIKit
import struct WordPressUI.GhostStyle
import XLPagerTabStrip
import Yosemite

/// Container view controller for a stats v4 time range that consists of a scrollable stack view of:
/// - Store stats data view (managed by child view controller `StoreStatsV4PeriodViewController`)
/// - Top performers header view (`TopPerformersSectionHeaderView`)
/// - Top performers data view (managed by child view controller `TopPerformerDataViewController`)
///
final class StoreStatsAndTopPerformersPeriodViewController: UIViewController {

    // MARK: Public Interface

    /// For navigation bar large title workaround.
    weak var scrollDelegate: DashboardUIScrollDelegate?

    /// Time range for this period
    let timeRange: StatsTimeRangeV4

    /// Stats interval granularity
    let granularity: StatsGranularityV4

    /// Whether site visit stats can be shown
    var siteVisitStatsMode: SiteVisitStatsMode = .default {
        didSet {
            storeStatsPeriodViewController.siteVisitStatsMode = siteVisitStatsMode
        }
    }

    /// Called when user pulls down to refresh
    var onPullToRefresh: () -> Void = {}

    /// Updated when reloading data.
    var currentDate: Date

    /// Updated when reloading data.
    var siteTimezone: TimeZone = .current {
        didSet {
            storeStatsPeriodViewController.siteTimezone = siteTimezone
        }
    }

    /// Timestamp for last successful data sync
    var lastFullSyncTimestamp: Date?

    /// Minimal time interval for data refresh
    var minimalIntervalBetweenSync: TimeInterval {
        switch timeRange {
        case .today:
            return 60
        case .thisWeek, .thisMonth:
            return 60*60
        case .thisYear:
            return 60*60*12
        }
    }

    // MARK: Subviews

    var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl(frame: .zero)
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    private var scrollView: UIScrollView = {
        return UIScrollView(frame: .zero)
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var topPerformersHeaderView = TopPerformersSectionHeaderView()

    // MARK: Child View Controllers

    private lazy var storeStatsPeriodViewController: StoreStatsV4PeriodViewController = {
        StoreStatsV4PeriodViewController(siteID: siteID, timeRange: timeRange, usageTracksEventEmitter: usageTracksEventEmitter)
    }()

    private lazy var inAppFeedbackCardViewController = InAppFeedbackCardViewController()

    /// An array of UIViews for the In-app Feedback Card. This will be dynamically shown
    /// or hidden depending on the configuration.
    private lazy var inAppFeedbackCardViewsForStackView: [UIView] = createInAppFeedbackCardViewsForStackView()

    private lazy var topPerformersPeriodViewController: TopPerformerDataViewController = {
        return TopPerformerDataViewController(siteID: siteID,
                                              siteTimeZone: siteTimezone,
                                              currentDate: currentDate,
                                              timeRange: timeRange,
                                              usageTracksEventEmitter: usageTracksEventEmitter)
    }()

    // MARK: Internal Properties

    private var childViewContrllers: [UIViewController] {
        return [storeStatsPeriodViewController, inAppFeedbackCardViewController, topPerformersPeriodViewController]
    }

    private let viewModel: StoreStatsAndTopPerformersPeriodViewModel

    private let siteID: Int64

    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter

    /// Subscriptions that should be cancelled on `deinit`.
    private var subscriptions = Set<AnyCancellable>()

    /// Create an instance of `self`.
    ///
    /// - Parameter canDisplayInAppFeedbackCard: If applicable, present the in-app feedback card.
    ///     The in-app feedback card may still not be presented depending on the constraints. But
    ///     setting this to `false`, will ensure that it will never be presented.
    ///
    init(siteID: Int64,
         timeRange: StatsTimeRangeV4,
         currentDate: Date,
         canDisplayInAppFeedbackCard: Bool,
         usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter) {
        self.siteID = siteID
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
        self.currentDate = currentDate
        self.viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: canDisplayInAppFeedbackCard)
        self.usageTracksEventEmitter = usageTracksEventEmitter

        super.init(nibName: nil, bundle: nil)

        configureInAppFeedbackCardViews()
        configureChildViewControllers()
        configureInAppFeedbackViewControllerAction()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        subscriptions.forEach {
            $0.cancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Fix any incomplete animation of the refresh control
        // when switching tabs mid-animation
        refreshControl.resetAnimation(in: scrollView)

        // After returning to the My Store tab, `restartGhostAnimation` is required to resume ghost animation.
        restartGhostAnimationIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.onViewDidAppear()
    }
}

extension StoreStatsAndTopPerformersPeriodViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.dashboardUIScrollViewDidScroll(scrollView)
    }

    /// We're not using scrollViewDidScroll because that gets executed even while
    /// the app is being loaded for the first time.
    ///
    /// Note: This also covers pull-to-refresh
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        usageTracksEventEmitter.interacted()
    }
}

// MARK: Public Interface
extension StoreStatsAndTopPerformersPeriodViewController {
    func clearAllFields() {
        storeStatsPeriodViewController.clearAllFields()
    }

    func displayGhostContent() {
        storeStatsPeriodViewController.displayGhostContent()
        topPerformersHeaderView.startGhostAnimation(style: Constants.ghostStyle)
        topPerformersPeriodViewController.displayGhostContent()
    }

    /// Removes the placeholder content for store stats.
    ///
    func removeStoreStatsGhostContent() {
        storeStatsPeriodViewController.removeGhostContent()
        topPerformersHeaderView.stopGhostAnimation()
    }

    /// Removes the placeholder content for top performers.
    ///
    func removeTopPerformersGhostContent() {
        topPerformersPeriodViewController.removeGhostContent()
    }

    /// Indicates if the receiver has Remote Stats, or not.
    ///
    var shouldDisplayStoreStatsGhostContent: Bool {
        return storeStatsPeriodViewController.shouldDisplayGhostContent
    }

    func restartGhostAnimationIfNeeded() {
        guard topPerformersHeaderView.superview != nil else {
            return
        }
        topPerformersHeaderView.restartGhostAnimation(style: Constants.ghostStyle)
    }
}

// MARK: - IndicatorInfoProvider Conformance (Tab Bar)
//
extension StoreStatsAndTopPerformersPeriodViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(
            title: timeRange.tabTitle,
            accessibilityIdentifier: "period-data-" + timeRange.rawValue + "-tab"
        )
    }
}

// MARK: - Provisioning and Utils

private extension StoreStatsAndTopPerformersPeriodViewController {
    func configureChildViewControllers() {
        childViewContrllers.forEach { childViewController in
            addChild(childViewController)
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    /// Observe and react to visibility events for the in-app feedback card.
    func configureInAppFeedbackCardViews() {
        guard viewModel.canDisplayInAppFeedbackCard else {
            return
        }

        viewModel.$isInAppFeedbackCardVisible.sink { [weak self] isVisible in
            guard let self = self else {
                return
            }

            let isHidden = !isVisible

            self.inAppFeedbackCardViewsForStackView.forEach { subView in
                // Check if the subView will change first. It looks like if we don't do this,
                // then StackView will not animate the change correctly.
                if subView.isHidden != isHidden {
                    UIView.animate(withDuration: 0.2) {
                        subView.isHidden = isHidden
                        self.stackView.setNeedsLayout()
                    }
                }
            }
        }.store(in: &subscriptions)
    }

    func configureSubviews() {
        view.addSubview(scrollView)
        view.backgroundColor = Constants.backgroundColor
        view.pinSubviewToSafeArea(scrollView)

        scrollView.refreshControl = refreshControl
        scrollView.delegate = self

        scrollView.addSubview(stackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.pinSubviewToAllEdges(stackView)
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])

        childViewContrllers.forEach { childViewController in
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }

        // Store stats.
        let storeStatsPeriodView = storeStatsPeriodViewController.view!
        stackView.addArrangedSubview(storeStatsPeriodView)
        NSLayoutConstraint.activate([
            storeStatsPeriodView.heightAnchor.constraint(equalToConstant: Constants.storeStatsPeriodViewHeight),
            ])

        // In-app Feedback Card
        stackView.addArrangedSubviews(inAppFeedbackCardViewsForStackView)

        // Top performers header.
        stackView.addArrangedSubview(topPerformersHeaderView)

        // Top performers.
        let topPerformersPeriodView = topPerformersPeriodViewController.view!
        stackView.addArrangedSubview(topPerformersPeriodView)

        childViewContrllers.forEach { childViewController in
            childViewController.didMove(toParent: self)
        }
    }

    /// Create in-app feedback views to be added to the main `stackView`.
    ///
    /// The views created are an empty space and the `inAppFeedbackCardViewController.view`.
    ///
    /// - SeeAlso: configureSubviews
    /// - Returns: The views or an empty array if something catastrophic happened.
    ///
    func createInAppFeedbackCardViewsForStackView() -> [UIView] {
        guard viewModel.canDisplayInAppFeedbackCard,
            let cardView = inAppFeedbackCardViewController.view else {
            return []
        }

        let emptySpaceView: UIView = {
            let view = UIView(frame: .zero)
            view.backgroundColor = nil
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalToConstant: 8)
            ])
            return view
        }()

        return [emptySpaceView, cardView]
    }

    func configureInAppFeedbackViewControllerAction() {
        inAppFeedbackCardViewController.onFeedbackGiven = { [weak self] in
            self?.viewModel.onInAppFeedbackCardAction()
        }
    }
}

// MARK: Actions
//
private extension StoreStatsAndTopPerformersPeriodViewController {
    @objc func pullToRefresh() {
        onPullToRefresh()
    }
}

private extension StoreStatsAndTopPerformersPeriodViewController {
    enum Constants {
        static let storeStatsPeriodViewHeight: CGFloat = 444
        static let ghostStyle: GhostStyle = .wooDefaultGhostStyle
        static let backgroundColor: UIColor = .systemBackground
    }
}
