import Combine
import UIKit
import struct WordPressUI.GhostStyle
import Yosemite
import WooFoundation

/// Container view controller for a stats v4 time range that consists of a scrollable stack view of:
/// - Store stats data view (managed by child view controller `StoreStatsV4PeriodViewController`)
/// - Top performers data view (managed by child view controller `TopPerformerDataViewController`)
///
final class StoreStatsAndTopPerformersPeriodViewController: UIViewController {

    // MARK: Public Interface

    /// Time range for this period
    let timeRange: StatsTimeRangeV4

    /// Whether site visit stats can be shown
    var siteVisitStatsMode: SiteVisitStatsMode = .default {
        didSet {
            storeStatsPeriodViewController.siteVisitStatsMode = siteVisitStatsMode
        }
    }

    /// Called when user pulls down to refresh
    var onPullToRefresh: @MainActor () async -> Void = {}

    /// Updated when reloading data.
    var currentDate: Date

    /// Updated when reloading data.
    var siteTimezone: TimeZone = .current {
        didSet {
            storeStatsPeriodViewController.siteTimezone = siteTimezone
            topPerformersPeriodViewController.siteTimeZone = siteTimezone
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

    private var containerView: UIView = {
        return .init(frame: .zero)
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        return stackView
    }()

    // MARK: Child View Controllers

    private lazy var storeStatsPeriodViewController: StoreStatsV4PeriodViewController = {
        StoreStatsV4PeriodViewController(siteID: siteID,
                                         timeRange: timeRange,
                                         currentDate: currentDate,
                                         usageTracksEventEmitter: usageTracksEventEmitter)
    }()

    private lazy var inAppFeedbackCardViewController = InAppFeedbackCardViewController()

    private lazy var analyticsHubButtonView = createAnalyticsHubButtonView()

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
        analyticsHubButtonView.startGhostAnimation(style: Constants.ghostStyle)
        topPerformersPeriodViewController.displayPlaceholderContent()
    }

    /// Removes the placeholder content for store stats.
    ///
    func removeStoreStatsGhostContent() {
        storeStatsPeriodViewController.removeGhostContent()
        analyticsHubButtonView.stopGhostAnimation()
    }

    /// Removes the placeholder content for top performers.
    ///
    func removeTopPerformersGhostContent() {
        topPerformersPeriodViewController.removePlaceholderContent()
    }

    /// Indicates if the receiver has Remote Stats, or not.
    ///
    var shouldDisplayStoreStatsGhostContent: Bool {
        return storeStatsPeriodViewController.shouldDisplayGhostContent
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
        view.addSubview(stackView)
        view.backgroundColor = Constants.backgroundColor
        view.pinSubviewToSafeArea(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        childViewContrllers.forEach { childViewController in
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }

        // Store stats.
        let storeStatsPeriodView = storeStatsPeriodViewController.view!
        stackView.addArrangedSubview(storeStatsPeriodView)

        // Analytics Hub ("See more") button
        stackView.addArrangedSubview(analyticsHubButtonView)

        // In-app Feedback Card
        stackView.addArrangedSubviews(inAppFeedbackCardViewsForStackView)

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

    func createAnalyticsHubButtonView() -> UIView {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.applySecondaryButtonStyle()
        button.setTitle(Localization.seeMoreButton.localizedCapitalized, for: .normal)
        button.addTarget(self, action: #selector(seeMoreButtonTapped), for: .touchUpInside)

        let view = UIView(frame: .zero)
        view.addSubview(button)
        view.pinSubviewToSafeArea(button, insets: Constants.buttonInsets)

        return view
    }

    func configureInAppFeedbackViewControllerAction() {
        inAppFeedbackCardViewController.onFeedbackGiven = { [weak self] in
            self?.viewModel.onInAppFeedbackCardAction()
        }
    }

    @objc func seeMoreButtonTapped() {
        viewModel.trackSeeMoreButtonTapped()
        let analyticsHubVC = AnalyticsHubHostingViewController(siteID: siteID,
                                                               timeZone: siteTimezone,
                                                               timeRange: timeRange,
                                                               usageTracksEventEmitter: usageTracksEventEmitter)
        show(analyticsHubVC, sender: self)
    }
}

// MARK: Actions
//
private extension StoreStatsAndTopPerformersPeriodViewController {
    @objc func pullToRefresh() {
        Task { @MainActor in
            await onPullToRefresh()
        }
    }
}

private extension StoreStatsAndTopPerformersPeriodViewController {
    enum Constants {
        static let storeStatsPeriodViewHeight: CGFloat = 444
        static let ghostStyle: GhostStyle = .wooDefaultGhostStyle
        static let backgroundColor: UIColor = .systemBackground
        static let buttonInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    enum Localization {
        static let seeMoreButton = NSLocalizedString("See more", comment: "Button on the stats dashboard that navigates user to the analytics hub")
    }
}
