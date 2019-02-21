import UIKit
import Gridicons
import CocoaLumberjack
import WordPressUI
import Yosemite


// MARK: - DashboardViewController
//
class DashboardViewController: UIViewController {

    // MARK: Properties

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var newOrdersContainerView: UIView!

    private var storeStatsViewController: StoreStatsViewController!
    private var newOrdersViewController: NewOrdersViewController!
    private var topPerformersViewController: TopPerformersViewController!

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    // MARK: View Lifecycle

    deinit {
        stopListeningToNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        startListeningToNotifications()
        tabBarItem.image = Gridicon.iconOfType(.statsAlt)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset title to prevent it from being empty right after login
        configureTitle()
        reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? StoreStatsViewController, segue.identifier == Segues.storeStatsSegue {
            storeStatsViewController = vc
        }
        if let vc = segue.destination as? NewOrdersViewController, segue.identifier == Segues.newOrdersSegue {
            newOrdersViewController = vc
            newOrdersViewController.delegate = self
        }
        if let vc = segue.destination as? TopPerformersViewController, segue.identifier == Segues.topPerformersSegue {
            topPerformersViewController = vc
        }
    }
}


// MARK: - Configuration
//
private extension DashboardViewController {

    func configureView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        scrollView.refreshControl = refreshControl
        newOrdersContainerView.isHidden = true // Hide the new orders vc by default
    }

    func configureNavigation() {
        configureTitle()
        configureNavigationItem()
    }

    private func configureTitle() {
        let myStore = NSLocalizedString("My store", comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard")
        title = StoresManager.shared.sessionManager.defaultSite?.name ?? myStore
        tabBarItem.title = myStore
    }

    private func configureNavigationItem() {
        let rightBarButton = UIBarButtonItem(image: Gridicon.iconOfType(.cog),
                                             style: .plain,
                                             target: self,
                                             action: #selector(settingsTapped))
        rightBarButton.tintColor = .white
        rightBarButton.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button.")
        rightBarButton.accessibilityTraits = .button
        rightBarButton.accessibilityHint = NSLocalizedString("Navigates to Settings.", comment: "VoiceOver accessibility hint, informing the user the button can be used to navigate to the Settings screen.")
        navigationItem.setRightBarButton(rightBarButton, animated: false)

        // Don't show the Dashboard title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }
}


// MARK: - Notifications
//
extension DashboardViewController {

    /// Wires all of the Notification Hooks
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultAccountWasUpdated), name: .defaultAccountWasUpdated, object: nil)
    }

    /// Stops listening to all related Notifications
    ///
    func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    /// Runs whenever the default Account is updated.
    ///
    @objc func defaultAccountWasUpdated() {
        guard storeStatsViewController != nil, StoresManager.shared.isAuthenticated == false else {
            return
        }

        configureTitle()

        storeStatsViewController.clearAllFields()
        applyHideAnimation(for: newOrdersContainerView)
    }
}

// MARK: - Public API
//
extension DashboardViewController {
    func presentSettings() {
        settingsTapped()
    }
}


// MARK: - Action Handlers
//
private extension DashboardViewController {

    @objc func settingsTapped() {
        WooAnalytics.shared.track(.settingsTapped)
        performSegue(withIdentifier: Segues.settingsSegue, sender: nil)
    }

    @objc func pullToRefresh() {
        WooAnalytics.shared.track(.dashboardPulledToRefresh)
        applyHideAnimation(for: newOrdersContainerView)
        reloadData()
    }
}


// MARK: - NewOrdersDelegate Conformance
//
extension DashboardViewController: NewOrdersDelegate {
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


// MARK: - Private Helpers
//
private extension DashboardViewController {

    func reloadData() {
        DDLogInfo("♻️ Requesting dashboard data be reloaded...")
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
            self?.refreshControl.endRefreshing()
            self?.configureTitle()

            if let error = reloadError {
                DDLogError("⛔️ Error loading dashboard: \(error)")
                self?.displaySyncingErrorNotice()
            }
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

    private func displaySyncingErrorNotice() {
        let title = NSLocalizedString("My store", comment: "My Store Notice Title for loading error")
        let message = NSLocalizedString("Unable to load content", comment: "Load Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.refreshControl.beginRefreshing()
            self?.reloadData()
        }

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Constants
//
private extension DashboardViewController {

    struct Segues {
        static let settingsSegue        = "ShowSettingsViewController"
        static let storeStatsSegue      = "StoreStatsEmbedSegue"
        static let newOrdersSegue       = "NewOrdersEmbedSegue"
        static let topPerformersSegue   = "TopPerformersEmbedSegue"
    }

    struct Constants {
        static let hideAnimationDuration: TimeInterval  = 0.25
        static let showAnimationDuration: TimeInterval  = 0.50
        static let showSpringDamping: CGFloat           = 0.7
        static let showSpringVelocity: CGFloat          = 0.0
    }
}
