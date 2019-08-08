import UIKit
import XLPagerTabStrip
import Yosemite

class StoreStatsAndTopPerformersPeriodViewController: UIViewController {

    let timeRange: StatsTimeRangeV4
    let granularity: StatsGranularityV4

    var shouldShowSiteVisitStats: Bool = true {
        didSet {
            storeStatsPeriodViewController.updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: shouldShowSiteVisitStats)
        }
    }

    var onPullToRefresh: () -> Void = {}

    /// Updated when reloading data.
    var currentDate: Date {
        didSet {
            storeStatsPeriodViewController.currentDate = currentDate
        }
    }

    // MARK: subviews
    //
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

    // MARK: child view controllers
    private lazy var storeStatsPeriodViewController: StoreStatsV4PeriodViewController = {
        return StoreStatsV4PeriodViewController(timeRange: timeRange, currentDate: currentDate)
    }()

    private lazy var topPerformersPeriodViewController: TopPerformerDataViewController = {
        return TopPerformerDataViewController(granularity: timeRange.topEarnerStatsGranularity)
    }()

    // MARK: internal properties
    private var childViewContrllers: [UIViewController] {
        return [storeStatsPeriodViewController, topPerformersPeriodViewController]
    }

    init(timeRange: StatsTimeRangeV4, currentDate: Date) {
        self.timeRange = timeRange
        self.granularity = timeRange.intervalGranularity
        self.currentDate = currentDate
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

// MARK: public interface
extension StoreStatsAndTopPerformersPeriodViewController {
    func clearAllFields() {
        storeStatsPeriodViewController.clearAllFields()
    }

    func displayGhostContent() {
        storeStatsPeriodViewController.displayGhostContent()
    }

    /// Unlocks the and removes the Placeholder Content
    ///
    func removeGhostContent() {
        storeStatsPeriodViewController.removeGhostContent()
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
        return IndicatorInfo(title: timeRange.tabTitle)
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

        let storeStatsPeriodView = storeStatsPeriodViewController.view!
        stackView.addArrangedSubview(storeStatsPeriodView)
        NSLayoutConstraint.activate([
            storeStatsPeriodView.heightAnchor.constraint(equalToConstant: 380),
            ])

        let topPerformersPeriodView = topPerformersPeriodViewController.view!
        stackView.addArrangedSubview(topPerformersPeriodView)
        NSLayoutConstraint.activate([
            topPerformersPeriodView.heightAnchor.constraint(equalToConstant: 359.5),
            topPerformersPeriodView.heightAnchor.constraint(greaterThanOrEqualToConstant: 359.5)
            ])

        childViewContrllers.forEach { childViewController in
            childViewController.didMove(toParent: self)
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
