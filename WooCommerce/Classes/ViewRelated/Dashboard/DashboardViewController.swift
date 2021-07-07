import UIKit
import Gridicons
import WordPressUI
import Yosemite


// MARK: - DashboardViewController
//
final class DashboardViewController: UIViewController {

    // MARK: Constants
    enum Constants {
        static let animationDuration = 0.2
    }
    
    // MARK: Properties

    private let siteID: Int64

    private let dashboardUIFactory: DashboardUIFactory
    private var dashboardUI: DashboardUI?

    // Used to enable subtitle with store name
    private var shouldShowStoreNameAsSubtitle: Bool {
        return ServiceLocator.stores.sessionManager.defaultSite?.name != nil && ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles)
    }

    private var titleName: String {
        guard !shouldShowStoreNameAsSubtitle else {
            return Localization.title
        }
        return ServiceLocator.stores.sessionManager.defaultSite?.name ?? ""
    }

    // MARK: Subviews

    private lazy var containerView: UIView = {
        return UIView(frame: .zero)
    }()

    private lazy var storeNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.applySubheadlineStyle()
        label.backgroundColor = .listForeground
        return label
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .listForeground
        view.layoutMargins = UIEdgeInsets(top: 0, left: navigationController?.navigationBar.layoutMargins.left ?? 0, bottom: 0, right: 0)
        view.isLayoutMarginsRelativeArrangement = true
        return view
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
        reloadDashboardUIStatsVersion(forced: false)
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
        configureSubtitle()
        configureNavigationItem()
    }

    func configureTabBarItem() {
        tabBarItem.image = .statsAltImage
        tabBarItem.title = Localization.title
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }

    func configureTitle() {
        navigationItem.title = titleName
    }

    func configureSubtitle() {
        guard shouldShowStoreNameAsSubtitle else {
            return
        }
        containerView.backgroundColor = .listForeground
        storeNameLabel.text = ServiceLocator.stores.sessionManager.defaultSite?.name ?? Localization.title
        stackView.addArrangedSubview(storeNameLabel)
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor)
        ])
    }

    func addViewBellowSubtitle(contentView: UIView) {
        guard shouldShowStoreNameAsSubtitle else {
            return
        }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: stackView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
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

    func reloadDashboardUIStatsVersion(forced: Bool) {
        dashboardUIFactory.reloadDashboardUI(onUIUpdate: { [weak self] dashboardUI in
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
                dashboardUI.scrollDelegate = self
            }
            self?.onDashboardUIUpdate(forced: forced, updatedDashboardUI: dashboardUI)
        })
    }
}

extension DashboardViewController: DashboardUIScrollDelegate {
    func dashboardUIScrollViewDidScroll(_ scrollView: UIScrollView) {
        hiddenScrollView.updateFromScrollViewDidScrollEventForLargeTitleWorkaround(scrollView)
        showOrHideSubtitle(offset: scrollView.contentOffset.y)
    }

    private func showOrHideSubtitle(offset: CGFloat) {
        guard shouldShowStoreNameAsSubtitle else {
            return
        }
        storeNameLabel.isHidden = offset > stackView.frame.height
        if offset < -stackView.frame.height {
            UIView.transition(with: storeNameLabel, duration: Constants.animationDuration,
                              options: .showHideTransitionViews,
                              animations: { [weak self] in
                                guard let self = self else { return }
                                self.storeNameLabel.isHidden = false
                          })
        }
    }
}

// MARK: - Updates
//
private extension DashboardViewController {
    func onDashboardUIUpdate(forced: Bool, updatedDashboardUI: DashboardUI) {
        defer {
            // Reloads data of the updated dashboard UI at the end.
            reloadData(forced: forced)
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
        addViewBellowSubtitle(contentView: contentView)

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
        reloadDashboardUIStatsVersion(forced: true)
    }

    func displaySyncingErrorNotice() {
        let title = NSLocalizedString("My store", comment: "My Store Notice Title for loading error")
        let message = NSLocalizedString("Unable to load content", comment: "Load Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.reloadData(forced: true)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Private Helpers
//
private extension DashboardViewController {
    func reloadData(forced: Bool) {
        DDLogInfo("♻️ Requesting dashboard data be reloaded...")
        dashboardUI?.reloadData(forced: forced, completion: { [weak self] in
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
