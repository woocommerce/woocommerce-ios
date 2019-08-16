import UIKit
import WordPressUI
import Yosemite

class DashboardStatsV3ViewController: UIViewController {
    var displaySyncingErrorNotice: () -> Void = {}

    var onPullToRefresh: () -> Void = {}

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

    private var stackView: UIStackView = {
        return UIStackView(arrangedSubviews: [])
    }()

    private var newOrdersContainerView: UIView = {
        return UIView(frame: .zero)
    }()

    private var newOrdersHeightConstraint: NSLayoutConstraint?

    // MARK: child view controllers
    //
    private var storeStatsViewController: StoreStatsViewController = {
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: StoreStatsViewController.self) else {
            fatalError()
        }
        return viewController
    }()

    private var newOrdersViewController: NewOrdersViewController = {
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: NewOrdersViewController.self) else {
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
        newOrdersContainerView.isHidden = true // Hide the new orders vc by default

        newOrdersViewController.delegate = self

        stackView.axis = .vertical

        configureContainerViews()
        configureChildViewControllerContainerViews()
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        if let containerVC = container as? NewOrdersViewController {
            newOrdersHeightConstraint?.constant = containerVC.preferredContentSize.height
        }
    }
}

// MARK: Actions
//
private extension DashboardStatsV3ViewController {
    @objc func pullToRefresh() {
        applyHideAnimation(for: newOrdersContainerView)
        onPullToRefresh()
    }
}

extension DashboardStatsV3ViewController: DashboardUI {
    func defaultAccountDidUpdate() {
        storeStatsViewController.clearAllFields()
        applyHideAnimation(for: newOrdersContainerView)
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
        newOrdersViewController.syncNewOrders() { error in
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

// MARK: - NewOrdersDelegate Conformance
//
extension DashboardStatsV3ViewController: NewOrdersDelegate {
    func didUpdateNewOrdersData(hasNewOrders: Bool) {
        if hasNewOrders {
            applyUnhideAnimation(for: newOrdersContainerView)
            WooAnalytics.shared.track(.dashboardUnfulfilledOrdersLoaded, withProperties: ["has_unfulfilled_orders": "true"])
        } else {
            applyHideAnimation(for: newOrdersContainerView)
            WooAnalytics.shared.track(.dashboardUnfulfilledOrdersLoaded, withProperties: ["has_unfulfilled_orders": "false"])
        }
    }
}

private extension DashboardStatsV3ViewController {
    func configureContainerViews() {
        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView)

        scrollView.addSubview(stackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 18),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
    }

    func configureChildViewControllerContainerViews() {
        // Store stats.
        let storeStatsView = storeStatsViewController.view!
        NSLayoutConstraint.activate([
            storeStatsView.heightAnchor.constraint(equalToConstant: 380),
            ])

        // Spacer view.
        let spacerView = UIView(frame: .zero)
        NSLayoutConstraint.activate([
            spacerView.heightAnchor.constraint(equalToConstant: 18),
            ])

        // New orders.
        let newOrdersView = newOrdersViewController.view!
        newOrdersContainerView.addSubview(newOrdersView)
        newOrdersContainerView.pinSubviewToAllEdges(newOrdersView)
        let newOrdersHeightConstraint = newOrdersContainerView.heightAnchor.constraint(equalToConstant: 80)
        self.newOrdersHeightConstraint = newOrdersHeightConstraint
        NSLayoutConstraint.activate([
            newOrdersHeightConstraint,
            newOrdersContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
            ])

        // Top performers.
        let topPerformersView = topPerformersViewController.view!
        NSLayoutConstraint.activate([
            topPerformersView.heightAnchor.constraint(equalToConstant: 465),
            topPerformersView.heightAnchor.constraint(greaterThanOrEqualToConstant: 465)
            ])

        // Add all child view controllers and their container/view to stack view's arranged subviews.
        let childViewControllers = [storeStatsViewController, newOrdersViewController, topPerformersViewController]
        childViewControllers.forEach { childViewController in
            addChild(childViewController)
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }

        let arrangedSubviews = [
            storeStatsView,
            spacerView,
            newOrdersContainerView,
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
