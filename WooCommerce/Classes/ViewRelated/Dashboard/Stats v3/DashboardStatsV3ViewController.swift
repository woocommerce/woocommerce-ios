import UIKit
import WordPressUI
import Yosemite

class DashboardStatsV3ViewController: UIViewController {
    var displaySyncingErrorNotice: () -> Void = {}

    var onPullToRefresh: () -> Void = {}

    /// Prevent stats banner to be shown, useful when the user has opted out of the banner for this session
    private var preventStatsBannerToBeShown = false

    /// MARK: TopBannerPresenter

    private(set) var topBannerView: UIView?

    // MARK: subviews
    //
    private var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl(frame: .zero)
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    private var scrollView: UIScrollView = {
        let returnValue = UIScrollView(frame: .zero)
        returnValue.backgroundColor = .systemColor(.systemGroupedBackground)
        return returnValue
    }()

    private var stackView: UIStackView = {
        let returnValue = UIStackView(arrangedSubviews: [])
        returnValue.backgroundColor = .systemColor(.systemGroupedBackground)
        return returnValue
    }()

    // MARK: child view controllers
    //
    private var storeStatsViewController: StoreStatsViewController = {
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: StoreStatsViewController.self) else {
            fatalError()
        }
        return viewController
    }()

    private var topPerformersViewController: TopPerformersViewController = {
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: TopPerformersViewController.self) else {
            fatalError()
        }
        return viewController
    }()

    // MARK: overrides
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.refreshControl = refreshControl
        stackView.axis = .vertical

        configureContainerViews()
        configureChildViewControllerContainerViews()
    }
}

// MARK: Actions
//
private extension DashboardStatsV3ViewController {
    @objc func pullToRefresh() {
        onPullToRefresh()
    }
}

extension DashboardStatsV3ViewController: DashboardUI {
    func defaultAccountDidUpdate() {
        storeStatsViewController.clearAllFields()
    }

    func reloadData(completion: @escaping () -> Void) {
        refreshControl.beginRefreshing()

        let group = DispatchGroup()

        var reloadError: Error? = nil

        group.enter()
        storeStatsViewController.syncAllStats() { error in
            if let error = error {
                reloadError = error
            }
            group.leave()
        }

        group.enter()
        topPerformersViewController.syncTopPerformers() { error in
            if let error = error {
                reloadError = error
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            completion()
            self?.refreshControl.endRefreshing()
            if let error = reloadError {
                DDLogError("⛔️ Error loading dashboard: \(error)")
                self?.handleSyncError(error: error)
            } else {
                self?.showSiteVisitors(true)
            }
        }
    }

    func remindStatsUpgradeLater() {
        hideTopBanner(animated: true)
        preventStatsBannerToBeShown = true
    }
}

extension DashboardStatsV3ViewController: TopBannerPresenter {
    func showTopBanner(_ topBannerView: UIView) {
        guard preventStatsBannerToBeShown == false else {
            return
        }

        self.topBannerView = topBannerView

        topBannerView.isHidden = true
        stackView.insertArrangedSubview(topBannerView, at: 0)
        UIView.animate(withDuration: 0.1) {
            topBannerView.isHidden = false
        }
    }

    func hideTopBanner(animated: Bool) {
        guard let banner = topBannerView else {
            return
        }
        guard animated else {
            removeTopBanner(banner)
            return
        }
        UIView.animate(withDuration: 0.1,
                       animations: {
                        banner.isHidden = true
        }, completion: { [weak self] isCompleted in
            guard isCompleted else {
                return
            }
            self?.removeTopBanner(banner)
        })
    }

    func removeTopBanner(_ topBanner: UIView) {
        topBanner.removeFromSuperview()
        topBannerView = nil
    }
}

private extension DashboardStatsV3ViewController {
    func showSiteVisitors(_ shouldShowSiteVisitors: Bool) {
        storeStatsViewController.updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: shouldShowSiteVisitors)
    }

    func handleSiteVisitStatsStoreError(error: SiteVisitStatsStoreError) {
        switch error {
        case .statsModuleDisabled, .noPermission:
            showSiteVisitors(false)
        default:
            displaySyncingErrorNotice()
        }
    }

    private func handleSyncError(error: Error) {
        switch error {
        case let siteVisitStatsStoreError as SiteVisitStatsStoreError:
            handleSiteVisitStatsStoreError(error: siteVisitStatsStoreError)
        default:
            displaySyncingErrorNotice()
        }
    }

    func applyUnhideAnimation(for view: UIView) {
        UIView.animate(withDuration: Constants.showAnimationDuration,
                       delay: 0,
                       usingSpringWithDamping: Constants.showSpringDamping,
                       initialSpringVelocity: Constants.showSpringVelocity,
                       options: .curveEaseOut,
                       animations: {
                        view.isHidden = false
                        view.alpha = UIKitConstants.alphaFull
        }) { _ in
            view.isHidden = false
            view.alpha = UIKitConstants.alphaFull
        }
    }

    func applyHideAnimation(for view: UIView) {
        UIView.animate(withDuration: Constants.hideAnimationDuration, animations: {
            view.isHidden = true
            view.alpha = UIKitConstants.alphaZero
        }, completion: { _ in
            view.isHidden = true
            view.alpha = UIKitConstants.alphaZero
        })
    }
}

private extension DashboardStatsV3ViewController {
    func configureContainerViews() {
        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)
        view.backgroundColor = .systemColor(.systemGroupedBackground)

        scrollView.addSubview(stackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.pinSubviewToAllEdges(stackView)
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
    }

    func configureChildViewControllerContainerViews() {
        // Top spacer view.
        let topSpacerView = UIView(frame: .zero)
        topSpacerView.backgroundColor = .systemColor(.systemGroupedBackground)
        NSLayoutConstraint.activate([
            topSpacerView.heightAnchor.constraint(equalToConstant: 18),
            ])

        // Store stats.
        let storeStatsView = storeStatsViewController.view!
        NSLayoutConstraint.activate([
            storeStatsView.heightAnchor.constraint(equalToConstant: 380),
            ])

        // Top performers.
        let topPerformersView = topPerformersViewController.view!
        NSLayoutConstraint.activate([
            topPerformersView.heightAnchor.constraint(equalToConstant: 465),
            topPerformersView.heightAnchor.constraint(greaterThanOrEqualToConstant: 465)
            ])

        // Add all child view controllers and their container/view to stack view's arranged subviews.
        let childViewControllers = [storeStatsViewController, topPerformersViewController]
        childViewControllers.forEach { childViewController in
            addChild(childViewController)
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }

        let arrangedSubviews = [
            topSpacerView,
            storeStatsView,
            topPerformersView
        ]
        arrangedSubviews.forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(subview)
        }

        childViewControllers.forEach { (childViewController) in
            childViewController.didMove(toParent: self)
        }
    }
}

// MARK: - Constants
//
private extension DashboardStatsV3ViewController {
    struct Constants {
        static let hideAnimationDuration: TimeInterval  = 0.25
        static let showAnimationDuration: TimeInterval  = 0.50
        static let showSpringDamping: CGFloat           = 0.7
        static let showSpringVelocity: CGFloat          = 0.0
    }
}
