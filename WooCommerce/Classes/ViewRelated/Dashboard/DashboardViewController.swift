import UIKit
import Gridicons
import WordPressUI
import Yosemite


// MARK: - DashboardViewController
//
class DashboardViewController: UIViewController {

    // MARK: Properties

    private var dashboardUI: DashboardUI?
    private var lastStatsVersion: StatsVersion?

    // MARK: Subviews

    private lazy var containerView: UIView = {
        return UIView(frame: .zero)
    }()

    // MARK: View Lifecycle

    deinit {
        stopListeningToNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        startListeningToNotifications()
        tabBarItem.image = .statsAltImage
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
        view.backgroundColor = StyleManager.tableViewBackgroundColor
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
        rightBarButton.tintColor = .white
        rightBarButton.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button.")
        rightBarButton.accessibilityTraits = .button
        rightBarButton.accessibilityHint = NSLocalizedString(
            "Navigates to Settings.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to navigate to the Settings screen."
        )
        navigationItem.setRightBarButton(rightBarButton, animated: false)

        // Don't show the Dashboard title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    func reloadDashboardUIStatsVersion() {
        // A container view is added to respond to safe area insets from the view controller.
        // This is needed when the child view controller's view has to use a frame-based layout
        // (e.g. when the child view controller is a `ButtonBarPagerTabStripViewController` subclass).
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(containerView)

        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        DashboardUIFactory.dashboardUIStatsVersion(isFeatureFlagOn: FeatureFlag.stats.enabled,
                                                   siteID: siteID,
                                                   onInitialUI: { [weak self] statsVersion in
                                                    self?.updateDashboardUI(statsVersion: statsVersion)
            },
                                                   onUpdate: { [weak self] statsVersion in
                                                    self?.onDashboardUIUpdate(statsVersion: statsVersion)
        })
    }
}

// MARK: - Updates
//
private extension DashboardViewController {
    func onDashboardUIUpdate(statsVersion: StatsVersion) {
        let lastStatsVersion = self.lastStatsVersion
        self.lastStatsVersion = statsVersion
        if lastStatsVersion == .v3 && statsVersion == .v4 {
            onDashboardUIStatsUpgrade(statsVersion: statsVersion)
        } else if lastStatsVersion == .v4 && statsVersion == .v3 {
            onDashboardUIStatsDowngrade(statsVersion: statsVersion)
        } else {
            updateDashboardUI(statsVersion: statsVersion)
        }
    }

    /// Stats v3 --> v4: shows top banner to announce stats v4 feature.
    func onDashboardUIStatsUpgrade(statsVersion: StatsVersion) {
        // TODO-1232: handle v3 --> v4 upgrading
        updateDashboardUI(statsVersion: statsVersion)
    }

    /// Stats v4 --> v3: reverts dashboard UI to v3 and shows top banner with explanations.
    func onDashboardUIStatsDowngrade(statsVersion: StatsVersion) {
        // TODO-1232: handle v4 --> v3 downgrading
        updateDashboardUI(statsVersion: statsVersion)
    }

    func updateDashboardUI(statsVersion: StatsVersion) {
        // Tears down the previous child view controller.
        if let previousDashboardUI = dashboardUI {
            remove(previousDashboardUI)
        }

        let dashboardUI = DashboardUIFactory.createDashboardUIAndSetUserPreference(statsVersion: statsVersion)
        self.dashboardUI = dashboardUI

        let contentView = dashboardUI.view!
        addChild(dashboardUI)
        containerView.addSubview(contentView)
        dashboardUI.didMove(toParent: self)

        dashboardUI.onPullToRefresh = { [weak self] in
            self?.pullToRefresh()
        }
        dashboardUI.displaySyncingErrorNotice = { [weak self] in
            self?.displaySyncingErrorNotice()
        }

        reloadData()
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
