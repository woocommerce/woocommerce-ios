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
    /// An array of UIViews for the In-app Feedback Card. This will be dynamically shown
    /// or hidden depending on the configuration.
    private lazy var inAppFeedbackCardViewsForStackView: [UIView] = createInAppFeedbackCardViewsForStackView()

    private lazy var topPerformersPeriodViewController: TopPerformerDataViewController = {
        return TopPerformerDataViewController(granularity: timeRange.topEarnerStatsGranularity)
    }()

    // MARK: Internal Properties

    private var childViewContrllers: [UIViewController] {
        return [storeStatsPeriodViewController, inAppFeedbackCardViewController, topPerformersPeriodViewController]
    }

    private let viewModel: StoreStatsAndTopPerformersPeriodViewModel

    /// Create an instance of `self`.
    ///
    /// - Parameter canDisplayInAppFeedbackCard: If applicable, present the in-app feedback card.
    ///     The in-app feedback card may still not be presented depending on the constraints. But
    ///     setting this to `false`, will ensure that it will never be presented.
    ///
    init(timeRange: StatsTimeRangeV4,
         currentDate: Date,
         canDisplayInAppFeedbackCard: Bool) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
        self.currentDate = currentDate
        self.viewModel = StoreStatsAndTopPerformersPeriodViewModel(canDisplayInAppFeedbackCard: canDisplayInAppFeedbackCard)

        super.init(nibName: nil, bundle: nil)

        configureInAppFeedbackCardViews()
        configureChildViewControllers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.onViewDidAppear()
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

        _ = viewModel.isInAppFeedbackCardVisible.subscribe { [weak self] isVisible in
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
        stackView.addArrangedSubviews(inAppFeedbackCardViewsForStackView)

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
