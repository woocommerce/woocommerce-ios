import Combine
import UIKit
import Gridicons
import WordPressUI
import Yosemite

// MARK: - DashboardViewController
//
final class DashboardViewController: UIViewController {

    // MARK: Properties

    private let siteID: Int64

    @Published private var dashboardUI: DashboardUI?

    private lazy var deprecatedStatsViewController = DeprecatedDashboardStatsViewController()
    private lazy var storeStatsAndTopPerformersViewController = StoreStatsAndTopPerformersViewController(siteID: siteID, dashboardViewModel: viewModel)

    // Used to enable subtitle with store name
    private var shouldShowStoreNameAsSubtitle: Bool = false

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

    /// A stack view to display `storeNameLabel` with additional margins
    ///
    private lazy var innerStackView: UIStackView = {
        let view = UIStackView()
        let horizontalMargin = Constants.horizontalMargin
        view.layoutMargins = UIEdgeInsets(top: 0, left: horizontalMargin, bottom: 0, right: horizontalMargin)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()

    /// A stack view for views displayed between the navigation bar and content (e.g. store name subtitle, top banner)
    ///
    private lazy var headerStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .listForeground
        view.axis = .vertical
        return view
    }()

    // Used to trick the navigation bar for large title (ref: issue 3 in p91TBi-45c-p2).
    private let hiddenScrollView = UIScrollView()

    /// Top banner that shows an error if there is a problem loading data
    ///
    private lazy var topBannerView = {
        ErrorTopBannerFactory.createTopBanner(isExpanded: false,
                                              expandedStateChangeHandler: {},
                                              onTroubleshootButtonPressed: { [weak self] in
                                                guard let self = self else { return }

                                                WebviewHelper.launch(WooConstants.URLs.troubleshootErrorLoadingData.asURL(), with: self)
                                              },
                                              onContactSupportButtonPressed: { [weak self] in
                                                guard let self = self else { return }
                                                ZendeskProvider.shared.showNewRequestIfPossible(from: self, with: nil)
                                              })
    }()

    /// Bottom Jetpack benefits banner, shown when the site is connected to Jetpack without Jetpack-the-plugin.
    private lazy var bottomJetpackBenefitsBannerController = JetpackBenefitsBannerHostingController()
    private var contentBottomToJetpackBenefitsBannerConstraint: NSLayoutConstraint?
    private var contentBottomToContainerConstraint: NSLayoutConstraint?
    private var isJetpackBenefitsBannerShown: Bool {
        bottomJetpackBenefitsBannerController.view?.superview != nil
    }

    /// A spacer view to add a margin below the top banner (between the banner and dashboard UI)
    ///
    private lazy var spacerView: UIView = {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: Constants.bannerBottomMargin).isActive = true
        view.backgroundColor = .listBackground
        return view
    }()

    private let viewModel: DashboardViewModel = .init()

    private var subscriptions = Set<AnyCancellable>()

    // MARK: View Lifecycle

    init(siteID: Int64) {
        self.siteID = siteID
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
        configureBottomJetpackBenefitsBanner()
        observeSiteForUIUpdates()
        observeBottomJetpackBenefitsBannerVisibilityUpdates()
        observeNavigationBarHeightForStoreNameLabelVisibility()
        observeStatsVersionForDashboardUIUpdates()
        Task { @MainActor in
            await reloadDashboardUIStatsVersion(forced: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset title to prevent it from being empty right after login
        configureTitle()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dashboardUI?.view.frame = containerView.bounds
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }
}

// MARK: - Configuration
//
private extension DashboardViewController {

    func configureView() {
        view.backgroundColor = Constants.backgroundColor
    }

    func configureNavigation() {
        configureTitle()
        configureHeaderStackView()
    }

    func configureTabBarItem() {
        tabBarItem.image = .statsAltImage
        tabBarItem.title = Localization.title
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }

    func configureTitle() {
        navigationItem.title = Localization.title
    }

    func configureHeaderStackView() {
        configureSubtitle()
        configureErrorBanner()
        containerView.addSubview(headerStackView)
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }

    func configureSubtitle() {
        storeNameLabel.text = ServiceLocator.stores.sessionManager.defaultSite?.name ?? Localization.title
        storeNameLabel.textColor = Constants.storeNameTextColor
        innerStackView.addArrangedSubview(storeNameLabel)
        headerStackView.addArrangedSubview(innerStackView)
    }

    func configureErrorBanner() {
        headerStackView.addArrangedSubviews([topBannerView, spacerView])
        // Don't show the error banner subviews until they are needed
        topBannerView.isHidden = true
        spacerView.isHidden = true
    }

    func addViewBelowHeaderStackView(contentView: UIView) {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        contentBottomToContainerConstraint = contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
    }

    func configureDashboardUIContainer() {
        hiddenScrollView.configureForLargeTitleWorkaround()
        // Adds the "hidden" scroll view to the root of the UIViewController for large titles.
        view.addSubview(hiddenScrollView)
        hiddenScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(hiddenScrollView, insets: .zero)

        // A container view is added to respond to safe area insets from the view controller.
        // This is needed when the child view controller's view has to use a frame-based layout
        // (e.g. when the child view controller is a `ButtonBarPagerTabStripViewController` subclass).
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(containerView)
    }

    func configureBottomJetpackBenefitsBanner() {
        bottomJetpackBenefitsBannerController.setActions { [weak self] in
            guard let self = self else { return }

            ServiceLocator.analytics.track(event: .jetpackBenefitsBanner(action: .tapped))

            let benefitsController = JetpackBenefitsHostingController()
            benefitsController.setActions { [weak self] in
                self?.dismiss(animated: true, completion: { [weak self] in
                    ServiceLocator.analytics.track(event: .jetpackInstallButtonTapped(source: .benefitsModal))

                    guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
                        return
                    }
                    let installController = JetpackInstallHostingController(siteID: site.siteID, siteURL: site.url, siteAdminURL: site.adminURL)
                    installController.setDismissAction { [weak self] in
                        self?.dismiss(animated: true, completion: nil)
                    }
                    self?.present(installController, animated: true, completion: nil)
                })
            } dismissAction: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
            self.present(benefitsController, animated: true, completion: nil)
        } dismissAction: { [weak self] in
            ServiceLocator.analytics.track(event: .jetpackBenefitsBanner(action: .dismissed))

            let dismissAction = AppSettingsAction.setJetpackBenefitsBannerLastDismissedTime(time: Date())
            ServiceLocator.stores.dispatch(dismissAction)

            self?.hideJetpackBenefitsBanner()
        }
    }

    func reloadDashboardUIStatsVersion(forced: Bool) async {
        await storeStatsAndTopPerformersViewController.reloadData(forced: forced)
    }

    func observeStatsVersionForDashboardUIUpdates() {
        viewModel.$statsVersion.removeDuplicates().sink { [weak self] statsVersion in
            guard let self = self else { return }
            let dashboardUI: DashboardUI
            switch statsVersion {
            case .v3:
                dashboardUI = self.deprecatedStatsViewController
            case .v4:
                dashboardUI = self.storeStatsAndTopPerformersViewController
            }
            dashboardUI.scrollDelegate = self
            self.onDashboardUIUpdate(forced: false, updatedDashboardUI: dashboardUI)
        }.store(in: &subscriptions)
    }

    /// Display the error banner at the top of the dashboard content (below the site title)
    ///
    func showTopBannerView() {
        topBannerView.isHidden = false
        spacerView.isHidden = false
    }

    /// Hide the error banner
    ///
    func hideTopBannerView() {
        topBannerView.isHidden = true
        spacerView.isHidden = true
    }

    func updateUI(site: Site) {
        let siteName = site.name
        guard siteName.isNotEmpty else {
            shouldShowStoreNameAsSubtitle = false
            storeNameLabel.text = nil
            return
        }
        shouldShowStoreNameAsSubtitle = true
        storeNameLabel.text = siteName
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
    func onDashboardUIUpdate(forced: Bool, updatedDashboardUI: DashboardUI) {
        defer {
            Task { @MainActor [weak self] in
                // Reloads data of the updated dashboard UI at the end.
                await self?.reloadData(forced: true)
            }
        }

        // Optimistically hide the error banner any time the dashboard UI updates (not just pull to refresh)
        hideTopBannerView()

        // No need to continue replacing the dashboard UI child view controller if the updated dashboard UI is the same as the currently displayed one.
        guard dashboardUI !== updatedDashboardUI else {
            return
        }

        // Tears down the previous child view controller.
        if let previousDashboardUI = dashboardUI {
            remove(previousDashboardUI)
        }

        let contentView = updatedDashboardUI.view!
        addChild(updatedDashboardUI)
        containerView.addSubview(contentView)
        updatedDashboardUI.didMove(toParent: self)
        addViewBelowHeaderStackView(contentView: contentView)

        // Sets `dashboardUI` after its view is added to the view hierarchy so that observers can update UI based on its view.
        dashboardUI = updatedDashboardUI

        updatedDashboardUI.onPullToRefresh = { [weak self] in
            await self?.pullToRefresh()
        }
        updatedDashboardUI.displaySyncingError = { [weak self] in
            self?.showTopBannerView()
        }
    }

    func updateJetpackBenefitsBannerVisibility(isBannerVisible: Bool, contentView: UIView) {
        if isBannerVisible {
            showJetpackBenefitsBanner(contentView: contentView)
        } else {
            hideJetpackBenefitsBanner()
        }
    }

    func showJetpackBenefitsBanner(contentView: UIView) {
        ServiceLocator.analytics.track(event: .jetpackBenefitsBanner(action: .shown))

        hideJetpackBenefitsBanner()
        guard let banner = bottomJetpackBenefitsBannerController.view else {
            return
        }
        contentBottomToContainerConstraint?.isActive = false

        addChild(bottomJetpackBenefitsBannerController)
        containerView.addSubview(banner)
        bottomJetpackBenefitsBannerController.didMove(toParent: self)

        banner.translatesAutoresizingMaskIntoConstraints = false

        // The banner height is calculated in `viewDidLayoutSubviews` to support rotation.
        let contentBottomToJetpackBenefitsBannerConstraint = banner.topAnchor.constraint(equalTo: contentView.bottomAnchor)
        self.contentBottomToJetpackBenefitsBannerConstraint = contentBottomToJetpackBenefitsBannerConstraint

        NSLayoutConstraint.activate([
            contentBottomToJetpackBenefitsBannerConstraint,
            banner.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            // Pins from the safe area layout bottom to accommodate offline banner.
            banner.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    func hideJetpackBenefitsBanner() {
        contentBottomToJetpackBenefitsBannerConstraint?.isActive = false
        contentBottomToContainerConstraint?.isActive = true
        if isJetpackBenefitsBannerShown {
            bottomJetpackBenefitsBannerController.view?.removeFromSuperview()
            remove(bottomJetpackBenefitsBannerController)
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
        let settingsViewController = SettingsViewController()
        ServiceLocator.analytics.track(.settingsTapped)
        show(settingsViewController, sender: self)
    }

    func pullToRefresh() async {
        ServiceLocator.analytics.track(.dashboardPulledToRefresh)
        await reloadDashboardUIStatsVersion(forced: true)
    }
}

// MARK: - Private Helpers
//
private extension DashboardViewController {
    @MainActor
    func reloadData(forced: Bool) async {
        DDLogInfo("♻️ Requesting dashboard data be reloaded...")
        await dashboardUI?.reloadData(forced: forced)
        configureTitle()
    }

    func observeSiteForUIUpdates() {
        ServiceLocator.stores.site.sink { [weak self] site in
            guard let self = self else { return }
            // We always want to update UI based on the latest site only if it matches the view controller's site ID.
            // When switching stores, this is triggered on the view controller of the previous site ID.
            guard let site = site, site.siteID == self.siteID else {
                return
            }
            self.updateUI(site: site)
            Task { @MainActor [weak self] in
                await self?.reloadData(forced: true)
            }
        }.store(in: &subscriptions)
    }

    func observeBottomJetpackBenefitsBannerVisibilityUpdates() {
        Publishers.CombineLatest(ServiceLocator.stores.site, $dashboardUI.eraseToAnyPublisher())
            .sink { [weak self] site, dashboardUI in
                guard let self = self else { return }

                guard let contentView = dashboardUI?.view else {
                    return
                }

                // Checks if Jetpack banner can be visible from app settings.
                let action = AppSettingsAction.loadJetpackBenefitsBannerVisibility(currentTime: Date(),
                                                                                   calendar: .current) { [weak self] isVisibleFromAppSettings in
                    guard let self = self else { return }

                    let shouldShowJetpackBenefitsBanner = site?.isJetpackCPConnected == true && isVisibleFromAppSettings

                    self.updateJetpackBenefitsBannerVisibility(isBannerVisible: shouldShowJetpackBenefitsBanner, contentView: contentView)
                }
                ServiceLocator.stores.dispatch(action)
            }.store(in: &subscriptions)
    }

    func observeNavigationBarHeightForStoreNameLabelVisibility() {
        navigationController?.navigationBar.publisher(for: \.frame, options: [.initial, .new])
            .map { $0.height }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] navigationBarHeight in
                guard let self = self else { return }

                guard self.shouldShowStoreNameAsSubtitle else {
                    return
                }
                self.storeNameLabel.isHidden = navigationBarHeight <= Constants.collapsedNavigationBarHeight
            })
            .store(in: &subscriptions)
    }
}

// MARK: Constants
private extension DashboardViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
    }

    enum Constants {
        static let bannerBottomMargin = CGFloat(8)
        static let horizontalMargin = CGFloat(16)
        static let storeNameTextColor: UIColor = .secondaryLabel
        static let backgroundColor: UIColor = .systemBackground
        static let collapsedNavigationBarHeight = CGFloat(44)
    }
}
