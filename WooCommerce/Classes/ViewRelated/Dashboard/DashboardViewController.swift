import UIKit
import Gridicons
import WordPressUI
import Yosemite


// MARK: - DashboardViewController
//
final class DashboardViewController: UIViewController {

    // MARK: Properties

    private let siteID: Int64

    private let dashboardUIFactory: DashboardUIFactory
    private var dashboardUI: DashboardUI?

    // MARK: Subviews

    private lazy var containerView: UIView = {
        return UIView(frame: .zero)
    }()

    // Used to trick the navigation bar for large title (ref: issue 3 in p91TBi-45c-p2).
    private let hiddenScrollView = UIScrollView()

    // MARK: View Lifecycle

    init(siteID: Int64) {
        self.siteID = siteID
        dashboardUIFactory = DashboardUIFactory(siteID: siteID)
        super.init(nibName: nil, bundle: nil)
        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func configureTabBarItem() {
        tabBarItem.image = .statsAltImage
        tabBarItem.title = Localization.title
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }

    func configureTitle() {
        navigationItem.title = ServiceLocator.stores.sessionManager.defaultSite?.name ?? Localization.title
    }

    private func configureNavigationItem() {
        let rightBarButton = UIBarButtonItem(image: .gearBarButtonItemImage,
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

        removeNavigationBackBarButtonText()
    }

    func configureDashboardUIContainer() {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
            hiddenScrollView.configureForLargeTitleWorkaround()
            // Adds the "hidden" scroll view to the root of the UIViewController for large titles.
            view.addSubview(hiddenScrollView)
            hiddenScrollView.translatesAutoresizingMaskIntoConstraints = false
            view.pinSubviewToAllEdges(hiddenScrollView, insets: .zero)
        }

        // A container view is added to respond to safe area insets from the view controller.
        // This is needed when the child view controller's view has to use a frame-based layout
        // (e.g. when the child view controller is a `ButtonBarPagerTabStripViewController` subclass).
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(containerView)
    }

    func reloadDashboardUIStatsVersion() {
        dashboardUIFactory.reloadDashboardUI(onUIUpdate: { [weak self] dashboardUI in
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
                dashboardUI.scrollDelegate = self
            }
            self?.onDashboardUIUpdate(updatedDashboardUI: dashboardUI)
        })
    }
}

extension DashboardViewController: DashboardUIScrollDelegate {
    func dashboardUIScrollViewDidScroll(_ scrollView: UIScrollView) {
        hiddenScrollView.updateFromScrollViewDidScrollEventForLargeTitleWorkaround(scrollView)
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
        let settingsViewController = SettingsViewController(nibName: nil, bundle: nil)
        ServiceLocator.analytics.track(.settingsTapped)
        show(settingsViewController, sender: self)
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

private extension DashboardViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
    }
}
