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

    /// Updated when reloading data.
    var currentDate: Date {
        didSet {
            storeStatsPeriodViewController.currentDate = currentDate
        }
    }

    // MARK: subviews
    //
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        return stackView
    }()

    // MARK: child view controllers
    private lazy var storeStatsPeriodViewController: StoreStatsV4PeriodViewController = {
        return StoreStatsV4PeriodViewController(timeRange: timeRange, currentDate: currentDate)
    }()

    // MARK: internal properties
    private var childViewContrllers: [UIViewController] {
        return [storeStatsPeriodViewController]
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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        view.pinSubviewToSafeArea(stackView)

        childViewContrllers.forEach { childViewController in
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }

        let storeStatsPeriodView = storeStatsPeriodViewController.view!
        stackView.addArrangedSubview(storeStatsPeriodView)
        NSLayoutConstraint.activate([
            storeStatsPeriodView.heightAnchor.constraint(equalToConstant: 380),
            ])

        childViewContrllers.forEach { childViewController in
            childViewController.didMove(toParent: self)
        }
    }
}
