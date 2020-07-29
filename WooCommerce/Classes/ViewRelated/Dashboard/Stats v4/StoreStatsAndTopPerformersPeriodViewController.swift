import UIKit
import XLPagerTabStrip
import Yosemite

/// Container view controller for a stats v4 time range that consists of a scrollable stack view of:
/// - Store stats data view (managed by child view controller `StoreStatsV4PeriodViewController`)
/// - Top performers header view (`TopPerformersSectionHeaderView`)
/// - Top performers data view (managed by child view controller `TopPerformerDataViewController`)
///
final class StoreStatsAndTopPerformersPeriodViewController: UIViewController {

    // MARK: Public Interface

    /// Time range for this period
    let timeRange: StatsTimeRangeV4

    /// Stats interval granularity
    let granularity: StatsGranularityV4

    /// Whether site visit stats can be shown
    var shouldShowSiteVisitStats: Bool = true {
        didSet {
            storeStatsPeriodViewController.updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: shouldShowSiteVisitStats)
        }
    }

    /// Called when user pulls down to refresh
    var onPullToRefresh: () -> Void = {}

    /// Updated when reloading data.
    var currentDate: Date {
        didSet {
            storeStatsPeriodViewController.currentDate = currentDate
        }
    }

    /// Updated when reloading data.
    var siteTimezone: TimeZone = .current {
        didSet {
            storeStatsPeriodViewController.siteTimezone = siteTimezone
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

    // MARK: Child View Controllers

    private lazy var storeStatsPeriodViewController: StoreStatsV4PeriodViewController = {
        return StoreStatsV4PeriodViewController(timeRange: timeRange, currentDate: currentDate)
    }()

    private lazy var inAppFeedbackCardViewController = InAppFeedbackCardViewController()

    private lazy var topPerformersPeriodViewController: TopPerformerDataViewController = {
        return TopPerformerDataViewController(granularity: timeRange.topEarnerStatsGranularity)
    }()

    // MARK: Internal Properties

    private var childViewContrllers: [UIViewController] {
        return [storeStatsPeriodViewController, inAppFeedbackCardViewController, topPerformersPeriodViewController]
    }

    private let featureFlagService: FeatureFlagService

    /// If applicable, present the in-app feedback. The in-app feedback may still not be presented
    /// depending on the constraints. But setting this to `false`, will ensure that it will
    /// never be presented.
    ///
    private let canDisplayInAppFeedback: Bool

    /// Create an instance of `self`.
    ///
    /// - Parameter canDisplayInAppFeedback: If applicable, present the in-app feedback. The in-app
    ///                                      feedback may still not be presented depending on the
    ///                                      constraints. But setting this to `false`, will ensure
    ///                                      that it will never be presented.
    ///
    init(timeRange: StatsTimeRangeV4,
         currentDate: Date,
         canDisplayInAppFeedback: Bool,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
        self.currentDate = currentDate
        self.canDisplayInAppFeedback = canDisplayInAppFeedback
        self.featureFlagService = featureFlagService
        super.init(nibName: nil, bundle: nil)
        configureChildViewControllers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSubviews()
    }
}

// MARK: Public Interface
extension StoreStatsAndTopPerformersPeriodViewController {
    func clearAllFields() {
        storeStatsPeriodViewController.clearAllFields()
    }

    func displayGhostContent() {
        storeStatsPeriodViewController.displayGhostContent()
        topPerformersPeriodViewController.displayGhostContent()
    }

    /// Unlocks the and removes the Placeholder Content
    ///
    func removeGhostContent() {
        storeStatsPeriodViewController.removeGhostContent()
        topPerformersPeriodViewController.removeGhostContent()
    }

    /// Indicates if the receiver has Remote Stats, or not.
    ///
    var shouldDisplayStoreStatsGhostContent: Bool {
        return storeStatsPeriodViewController.shouldDisplayGhostContent
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

private extension StoreStatsAndTopPerformersPeriodViewController {
    func configureChildViewControllers() {
        childViewContrllers.forEach { childViewController in
            addChild(childViewController)
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    func configureSubviews() {
        view.addSubview(scrollView)
        view.pinSubviewToSafeArea(scrollView)

        scrollView.refreshControl = refreshControl

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
            storeStatsPeriodView.heightAnchor.constraint(equalToConstant: 380),
            ])

        // In-app Feedback Card
        let inAppFeedbackCardViews = createInAppFeedbackCardViewsForStackView()
        inAppFeedbackCardViews.forEach {
            stackView.addArrangedSubview($0)
        }

        // Top performers header.
        let topPerformersHeaderView = TopPerformersSectionHeaderView(title:
            NSLocalizedString("Top Performers",
                              comment: "Header label for Top Performers section of My Store tab.")
                .uppercased())
        stackView.addArrangedSubview(topPerformersHeaderView)
        let headerTopBorderView = createBorderView()
        let headerBottomBorderView = createBorderView()
        topPerformersHeaderView.addSubview(headerTopBorderView)
        topPerformersHeaderView.addSubview(headerBottomBorderView)
        NSLayoutConstraint.activate([
            topPerformersHeaderView.heightAnchor.constraint(equalToConstant: 44),
            // Top border view
            headerTopBorderView.topAnchor.constraint(equalTo: topPerformersHeaderView.topAnchor),
            headerTopBorderView.leadingAnchor.constraint(equalTo: topPerformersHeaderView.leadingAnchor),
            headerTopBorderView.trailingAnchor.constraint(equalTo: topPerformersHeaderView.trailingAnchor),
            // Bottom border view
            headerBottomBorderView.bottomAnchor.constraint(equalTo: topPerformersHeaderView.bottomAnchor),
            headerBottomBorderView.leadingAnchor.constraint(equalTo: topPerformersHeaderView.leadingAnchor),
            headerBottomBorderView.trailingAnchor.constraint(equalTo: topPerformersHeaderView.trailingAnchor),
            ])

        // Top performers.
        let topPerformersPeriodView = topPerformersPeriodViewController.view!
        stackView.addArrangedSubview(topPerformersPeriodView)
        stackView.addArrangedSubview(createBorderView())

        // Empty padding view at the bottom.
        let emptyView = UIView(frame: .zero)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.backgroundColor = .clear
        NSLayoutConstraint.activate([
            emptyView.heightAnchor.constraint(equalToConstant: 44),
            ])
        stackView.addArrangedSubview(emptyView)

        childViewContrllers.forEach { childViewController in
            childViewController.didMove(toParent: self)
        }
    }

    /// Create in-app feedback views to be added to the main `stackView`.
    ///
    /// The views created are an empty space and the `inAppFeedbackCardViewController.view`.
    ///
    /// - SeeAlso: configureSubviews
    /// - Returns: The views or empty array if we do not need in-app feedback from the user.
    ///
    func createInAppFeedbackCardViewsForStackView() -> [UIView] {
        guard canDisplayInAppFeedback,
            featureFlagService.isFeatureFlagEnabled(.inAppFeedback),
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

    func createBorderView() -> UIView {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemColor(.separator)
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        return view
    }
}

// MARK: Actions
//
private extension StoreStatsAndTopPerformersPeriodViewController {
    @objc func pullToRefresh() {
        onPullToRefresh()
    }
}
