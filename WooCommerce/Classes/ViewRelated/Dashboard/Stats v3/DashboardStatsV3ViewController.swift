import UIKit
import WordPressUI
import Yosemite

extension UIView {
    public func pinSubviewToAllEdges(_ subview: UIView, insets: UIEdgeInsets) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: subview.leadingAnchor),
            trailingAnchor.constraint(equalTo: subview.trailingAnchor),
            topAnchor.constraint(equalTo: subview.topAnchor),
            bottomAnchor.constraint(equalTo: subview.bottomAnchor),
            ])
    }
}

extension UIStoryboard {
    func instantiateViewController<T: NSObject>(ofClass classType: T.Type) -> T? {
        let identifier = classType.classNameWithoutNamespaces
        return instantiateViewController(withIdentifier: identifier) as? T
    }
}

class DashboardStatsV3ViewController: UIViewController {
    // MARK: subviews
    var refreshControl: UIRefreshControl = {
        return UIRefreshControl(frame: .zero)
    }()

    private var scrollView: UIScrollView = {
        return UIScrollView(frame: .zero)
    }()

    private var stackView: UIStackView = {
        return UIStackView(arrangedSubviews: [])
    }()

    private var storeStatsView: UIView {
        return storeStatsViewController.view
    }

    // MARK: child view controllers
    private var storeStatsViewController: StoreStatsViewController = {
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: StoreStatsViewController.self) else {
            fatalError()
        }
        return viewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.refreshControl = refreshControl

        configureContainerViews()
        configureChildViewControllers()
        configureChildViewControllerContainerViews()
    }
}

extension DashboardStatsV3ViewController: DashboardUI {
    func defaultAccountDidUpdate() {
        storeStatsViewController.clearAllFields()
    }

    func reloadData(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        var reloadError: Error? = nil

        group.enter()
        storeStatsViewController.syncAllStats() { error in
            if let error = error {
                reloadError = error
            }
            group.leave()
        }

//        group.enter()
//        newOrdersViewController.syncNewOrders() { error in
//            if let error = error {
//                reloadError = error
//            }
//            group.leave()
//        }
//
//        group.enter()
//        topPerformersViewController.syncTopPerformers() { error in
//            if let error = error {
//                reloadError = error
//            }
//            group.leave()
//        }

        group.notify(queue: .main) { [weak self] in
            completion()
            self?.refreshControl.endRefreshing()
            if let error = reloadError {
                DDLogError("⛔️ Error loading dashboard: \(error)")
                self?.handleSyncError(error: error)
            } else {
                self?.updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: true)
            }
        }
    }
}

private extension DashboardStatsV3ViewController {
    func updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: Bool) {
        storeStatsViewController.updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: shouldShowSiteVisitStats)
    }

    func handleSiteVisitStatsStoreError(error: SiteVisitStatsStoreError) {
        switch error {
        case .statsModuleDisabled, .noPermission:
            updateSiteVisitStatsVisibility(shouldShowSiteVisitStats: false)
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
        let storeStatsContainerView = UIView(frame: .zero)
        storeStatsContainerView.addSubview(storeStatsView)
        storeStatsContainerView.pinSubviewAtCenter(storeStatsView)
        storeStatsContainerView.translatesAutoresizingMaskIntoConstraints = false
        storeStatsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            storeStatsContainerView.heightAnchor.constraint(equalToConstant: 380),
            storeStatsView.widthAnchor.constraint(equalTo: storeStatsContainerView.widthAnchor),
            storeStatsView.heightAnchor.constraint(equalTo: storeStatsContainerView.heightAnchor)
            ])

        let arrangedSubviews = [
            storeStatsContainerView
            ]
        arrangedSubviews.forEach { subview in
            stackView.addArrangedSubview(subview)
        }
    }

    func configureChildViewControllers() {
        let childViewControllers = [storeStatsViewController]
        childViewControllers.forEach { (childViewController) in
            add(childViewController)
        }
    }
}
