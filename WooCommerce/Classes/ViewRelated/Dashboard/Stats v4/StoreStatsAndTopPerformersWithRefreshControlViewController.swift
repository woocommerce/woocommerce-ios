import UIKit

/// A wrapper of `StoreStatsAndTopPerformersViewController` that contains a scroll view of `StoreStatsAndTopPerformersViewController` and refresh control.
class StoreStatsAndTopPerformersWithRefreshControlViewController: UIViewController {

    // MARK: DashboardUI
    //
    var displaySyncingErrorNotice: () -> Void = {} {
        didSet {
            storeStatsAndTopPerformersViewController.displaySyncingErrorNotice = displaySyncingErrorNotice
        }
    }

    var onPullToRefresh: () -> Void = {} {
        didSet {
            storeStatsAndTopPerformersViewController.onPullToRefresh = onPullToRefresh
        }
    }

    // MARK: subviews
    //
    private var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl(frame: .zero)
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    private var scrollView: UIScrollView = {
        return UIScrollView(frame: .zero)
    }()

    // MARK: child view controller
    private lazy var storeStatsAndTopPerformersViewController: StoreStatsAndTopPerformersViewController = {
        return StoreStatsAndTopPerformersViewController(nibName: nil, bundle: nil)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureContainerViews()
    }
}

extension StoreStatsAndTopPerformersWithRefreshControlViewController: DashboardUI {
    func defaultAccountDidUpdate() {
        storeStatsAndTopPerformersViewController.defaultAccountDidUpdate()
    }

    func reloadData(completion: @escaping () -> Void) {
        storeStatsAndTopPerformersViewController.reloadData(completion: completion)
    }
}

private extension StoreStatsAndTopPerformersWithRefreshControlViewController {
    func configureContainerViews() {
        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)

        configureChildViewController()

        scrollView.refreshControl = refreshControl
    }

    func configureChildViewController() {
        storeStatsAndTopPerformersViewController.refreshControl = refreshControl

        addChild(storeStatsAndTopPerformersViewController)

        let contentView = storeStatsAndTopPerformersViewController.view!
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.pinSubviewToAllEdges(contentView)
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])

        storeStatsAndTopPerformersViewController.didMove(toParent: self)
    }
}

// MARK: Actions
//
private extension StoreStatsAndTopPerformersWithRefreshControlViewController {
    @objc func pullToRefresh() {
        onPullToRefresh()
    }
}
