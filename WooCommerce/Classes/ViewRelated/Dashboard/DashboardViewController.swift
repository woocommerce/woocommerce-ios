import UIKit
import Gridicons
import WordPressUI
import Yosemite


// MARK: - DashboardViewController
//
class DashboardViewController: UIViewController {

    // MARK: Properties

    private var siteID: Int64?

    private var dashboardUIFactory: DashboardUIFactory?
    private var dashboardUI: DashboardUI?

    // MARK: Subviews

    private lazy var containerView: UIView = {
        return UIView(frame: .zero)
    }()

    // MARK: View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        startListeningToNotifications()
        tabBarItem.image = .statsAltImage
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureView()
        configureDashboardUIContainer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset title to prevent it from being empty right after login
        configureTitle()
        reloadDashboardUIStatsVersion()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dashboardUI?.view.frame = containerView.bounds
    }
}


// MARK: - Configuration
//
private extension DashboardViewController {

    func configureView() {
        view.backgroundColor = .listBackground
    }

    func configureNavigation() {
        configureTitle()
        configureNavigationItem()
    }

    private func configureTitle() {
        let myStore = NSLocalizedString(
            "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
        title = ServiceLocator.stores.sessionManager.defaultSite?.name ?? myStore
        tabBarItem.title = myStore
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }

    private func resetTitle() {
        let myStore = NSLocalizedString(
            "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
        title = myStore
        tabBarItem.title = myStore
    }

    private func configureNavigationItem() {
        let rightBarButton = UIBarButtonItem(image: .cogImage,
                                             style: .plain,
                                             target: self,
                                             action: #selector(settingsTapped))
        rightBarButton.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button.")
        rightBarButton.accessibilityTraits = .button
        rightBarButton.accessibilityHint = NSLocalizedString(
            "Navigates to Settings.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to navigate to the Settings screen."
        )
        rightBarButton.accessibilityIdentifier = "dashboard-settings-button"
        navigationItem.setRightBarButton(rightBarButton, animated: false)

        // Don't show the Dashboard title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    func configureDashboardUIContainer() {
        // A container view is added to respond to safe area insets from the view controller.
        // This is needed when the child view controller's view has to use a frame-based layout
        // (e.g. when the child view controller is a `ButtonBarPagerTabStripViewController` subclass).
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(containerView)
    }

    func reloadDashboardUIStatsVersion() {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }
        if siteID != self.siteID {
            dashboardUIFactory = DashboardUIFactory(siteID: siteID)
            self.siteID = siteID
        }

        dashboardUIFactory?.reloadDashboardUI(isFeatureFlagOn: ServiceLocator.featureFlagService.isFeatureFlagEnabled(.stats),
                                              onUIUpdate: { [weak self] dashboardUI in
                                                self?.onDashboardUIUpdate(updatedDashboardUI: dashboardUI)
        })
    }
}

// MARK: - Updates
//
private extension DashboardViewController {
    func onDashboardUIUpdate(updatedDashboardUI: DashboardUI) {
        defer {
            // Reloads data of the updated dashboard UI at the end.
            reloadData()
        }

        // No need to continue replacing the dashboard UI child view controller if the updated dashboard UI is the same as the currently displayed one.
        guard dashboardUI !== updatedDashboardUI else {
            return
        }

        // Tears down the previous child view controller.
        if let previousDashboardUI = dashboardUI {
            remove(previousDashboardUI)
        }

        dashboardUI = updatedDashboardUI

        let contentView = updatedDashboardUI.view!
        addChild(updatedDashboardUI)
        containerView.addSubview(contentView)
        updatedDashboardUI.didMove(toParent: self)

        updatedDashboardUI.onPullToRefresh = { [weak self] in
            self?.pullToRefresh()
        }
        updatedDashboardUI.displaySyncingErrorNotice = { [weak self] in
            self?.displaySyncingErrorNotice()
        }
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

    /// Runs whenever the default Account is updated.
    ///
    @objc func defaultAccountWasUpdated() {
        guard isViewLoaded, ServiceLocator.stores.isAuthenticated == false else {
            return
        }

        resetTitle()
        dashboardUI?.defaultAccountDidUpdate()
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
        ServiceLocator.analytics.track(.settingsTapped)
        performSegue(withIdentifier: Segues.settingsSegue, sender: nil)
    }

    func pullToRefresh() {
        ServiceLocator.analytics.track(.dashboardPulledToRefresh)
        reloadDashboardUIStatsVersion()
    }

    func displaySyncingErrorNotice() {
        let title = NSLocalizedString("My store", comment: "My Store Notice Title for loading error")
        let message = NSLocalizedString("Unable to load content", comment: "Load Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.reloadData()
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Private Helpers
//
private extension DashboardViewController {
    func reloadData() {
        DDLogInfo("♻️ Requesting dashboard data be reloaded...")
        dashboardUI?.reloadData(completion: { [weak self] in
            self?.configureTitle()
        })
    }
}

// MARK: - Constants
//
private extension DashboardViewController {

    struct Segues {
        static let settingsSegue        = "ShowSettingsViewController"
    }
}
