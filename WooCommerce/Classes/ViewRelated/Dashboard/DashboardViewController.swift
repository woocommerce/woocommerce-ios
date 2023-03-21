import Combine
import UIKit
import Gridicons
import WordPressUI
import Yosemite
import SwiftUI

// MARK: - DashboardViewController
//
final class DashboardViewController: UIViewController {

    // MARK: Properties

    private let siteID: Int64

    @Published private var dashboardUI: DashboardUI?

    private lazy var deprecatedStatsViewController = DeprecatedDashboardStatsViewController()
    private lazy var storeStatsAndTopPerformersViewController =
    StoreStatsAndTopPerformersViewController(siteID: siteID,
                                             dashboardViewModel: viewModel,
                                             usageTracksEventEmitter: usageTracksEventEmitter)

    // Used to enable subtitle with store name
    private var shouldShowStoreNameAsSubtitle: Bool = false

    // MARK: Subviews

    /// The top-level stack view that contains the scroll view and other sticky views like the Jetpack benefits banner.
    private lazy var stackView: UIStackView = {
        .init(arrangedSubviews: [])
    }()

    /// The top-level scroll view. All subviews should not be a scroll view to avoid nested scroll views that can result in unexpected scrolling behavior.
    private lazy var containerView: UIScrollView = {
        return UIScrollView(frame: .zero)
    }()

    /// Refresh control for the scroll view.
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl(frame: .zero)
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    /// Embedded in the scroll view. Contains the header view and dashboard content view.
    private lazy var containerStackView: UIStackView = {
        .init(arrangedSubviews: [])
    }()

    private lazy var storeNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.applySubheadlineStyle()
        label.backgroundColor = .listForeground(modal: false)
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
        view.backgroundColor = .listForeground(modal: false)
        view.axis = .vertical
        view.directionalLayoutMargins = .init(top: 0, leading: 0, bottom: Constants.tabStripSpacing, trailing: 0)
        view.spacing = Constants.headerStackViewSpacing
        return view
    }()

    /// Stores an animator for showing/hiding the header view while there is an animation in progress
    /// so we can interrupt and reverse if needed
    private var headerAnimator: UIViewPropertyAnimator?

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
            let supportForm = SupportFormHostingController(viewModel: .init())
            supportForm.show(from: self)
        })
    }()

    private var announcementViewHostingController: ConstraintsUpdatingHostingController<AnnouncementCardWrapper>?

    private var announcementView: UIView?

    /// Holds a reference to the Free Trial Banner view, Needed to be able to hide it when needed.
    ///
    private var freeTrialBanner: UIView?

    /// Onboarding card.
    private var onboardingHostingController: StoreOnboardingViewHostingController?
    private var onboardingView: UIView?

    /// Bottom Jetpack benefits banner, shown when the site is connected to Jetpack without Jetpack-the-plugin.
    private lazy var bottomJetpackBenefitsBannerController = JetpackBenefitsBannerHostingController()
    private var isJetpackBenefitsBannerShown: Bool {
        bottomJetpackBenefitsBannerController.view?.superview != nil
    }
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?

    /// A spacer view to add a margin below the top banner (between the banner and dashboard UI)
    ///
    private lazy var spacerView: UIView = {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: Constants.bannerBottomMargin).isActive = true
        view.backgroundColor = .listBackground
        return view
    }()

    private let viewModel: DashboardViewModel = .init()

    private let usageTracksEventEmitter = StoreStatsUsageTracksEventEmitter()

    private var subscriptions = Set<AnyCancellable>()
    private var navbarObserverSubscription: AnyCancellable?

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
        registerUserActivity()
        configureNavigation()
        configureView()
        configureStackView()
        configureDashboardUIContainer()
        configureBottomJetpackBenefitsBanner()
        observeSiteForUIUpdates()
        observeBottomJetpackBenefitsBannerVisibilityUpdates()
        observeStatsVersionForDashboardUIUpdates()
        observeAnnouncements()
        observeShowWebViewSheet()
        observeAddProductTrigger()
        observeOnboardingVisibility()
        observeFreeTrialBannerVisibility()

        Task { @MainActor in
            await viewModel.syncAnnouncements(for: siteID)
            await reloadDashboardUIStatsVersion(forced: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset title to prevent it from being empty right after login
        configureTitle()

        // Proactively update the free trial banner every time we navigate to the dashboard.
        viewModel.syncFreeTrialBanner(siteID: siteID)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateHeaderVisibility(animated: false)
        observeNavigationBarHeightForHeaderVisibility()
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopObservingNavigationBarHeightForHeaderVisibility()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dashboardUI?.view.frame = containerView.bounds
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }
}

// MARK: - Header animation
private extension DashboardViewController {
    func showHeaderWithoutAnimation() {
        headerStackView.isHidden = false
    }

    func hideHeaderWithoutAnimation() {
        headerStackView.isHidden = true
    }

    func updateHeaderVisibility(animated: Bool) {
        // Only hide/show header when the dashboard content is taller than the scroll view.
        // Otherwise, the large title state (navigation collapsed state) can be ambiguous because the scroll view becomes not scrollable.
        guard let dashboardUI, dashboardUI.view.frame.height > containerView.frame.height else {
            return
        }
        if navigationBarIsCollapsed() {
            hideHeader(animated: animated)
        } else {
            showHeader(animated: animated)
        }
    }

    func showHeader(animated: Bool) {
        if animated {
            animateHeaderVisibility { [weak self] in
                self?.showHeaderWithoutAnimation()
            }
        } else {
            showHeaderWithoutAnimation()
        }
    }

    func hideHeader(animated: Bool) {
        if animated {
            animateHeaderVisibility { [weak self] in
                self?.hideHeaderWithoutAnimation()
            }
        } else {
            hideHeaderWithoutAnimation()
        }
    }

    func animateHeaderVisibility(animations: @escaping () -> Void) {
        if headerAnimator?.isRunning == true {
            headerAnimator?.stopAnimation(true)
        }
        headerAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: Constants.animationDurationSeconds,
            delay: 0,
            animations: animations,
            completion: { [weak self] position in
                self?.headerAnimator = nil
            })
    }

    func navigationBarIsCollapsed() -> Bool {
        guard let frame = navigationController?.navigationBar.frame else {
            return false
        }

        return frame.height <= collapsedNavigationBarHeight
    }

    var collapsedNavigationBarHeight: CGFloat {
        if self.traitCollection.userInterfaceIdiom == .pad {
            return Constants.iPadCollapsedNavigationBarHeight
        } else {
            return Constants.iPhoneCollapsedNavigationBarHeight
        }
    }
}

extension DashboardViewController: UIScrollViewDelegate {
    /// We're not using scrollViewDidScroll because that gets executed even while
    /// the app is being loaded for the first time.
    ///
    /// Note: This also covers pull-to-refresh
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        usageTracksEventEmitter.interacted()
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
        configureContainerStackView()
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

    func configureContainerStackView() {
        containerStackView.axis = .vertical
        containerView.addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinSubviewToAllEdges(containerStackView)
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalTo: containerStackView.widthAnchor)
        ])
    }

    func configureHeaderStackView() {
        configureSubtitle()
        configureErrorBanner()
        containerStackView.addArrangedSubview(headerStackView)
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
        let indexAfterHeader = (containerStackView.arrangedSubviews.firstIndex(of: headerStackView) ?? -1) + 1
        containerStackView.insertArrangedSubview(contentView, at: indexAfterHeader)
    }

    func configureStackView() {
        stackView.axis = .vertical
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(stackView)
    }

    /// Adds a Free Trial bar at the bottom of the screen.
    ///
    func addFreeTrialBar(contentText: String) {
        let freeTrialViewController = FreeTrialBannerHostingViewController(mainText: contentText) { [weak self] in
            self?.showUpgradePlanWebView()
        }
        freeTrialViewController.view.translatesAutoresizingMaskIntoConstraints = false

        self.stackView.addSubview(freeTrialViewController.view)
        NSLayoutConstraint.activate([
            freeTrialViewController.view.leadingAnchor.constraint(equalTo: self.stackView.leadingAnchor),
            freeTrialViewController.view.trailingAnchor.constraint(equalTo: self.stackView.trailingAnchor),
            freeTrialViewController.view.bottomAnchor.constraint(equalTo: self.stackView.bottomAnchor)

        ])

        // Adjust the main container content inset to prevent it from being hidden by the `freeTrialViewController`
        DispatchQueue.main.async {
            self.containerView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: freeTrialViewController.view.frame.size.height, right: 0)
        }

        // Store a reference to it to manipulate it later in `removeFreeTrialBanner`.
        freeTrialBanner = freeTrialViewController.view
    }

    /// Removes the Free Trial Banner when possible.
    ///
    func removeFreeTrialBanner() {
        guard let banner = freeTrialBanner else {
            return
        }

        banner.removeFromSuperview()
        containerView.contentInset = .zero // Resets the content offset of main scroll view. Was adjusted previously in `addFreeTrialBar`
    }

    /// Shows a web view for the merchant to update their site plan.
    ///
    func showUpgradePlanWebView() {
        ServiceLocator.analytics.track(event: .FreeTrial.freeTrialUpgradeNowTapped(source: .banner))

        // These URLs should be stored elsewhere.
        // I'll wait until I reuse them in the plans menu to decide what is the best place for them.
        // https://github.com/woocommerce/woocommerce-ios/issues/9057
        guard let upgradeURL = URL(string: "https://wordpress.com/plans/\(siteID)") else { return }
        let exitTrigger = "my-plan/trial-upgraded" // When a site is upgraded from a trial, this URL path is invoked.

        let viewModel = DefaultAuthenticatedWebViewModel(title: Localization.upgradeNow,
                                                         initialURL: upgradeURL,
                                                         urlToTriggerExit: exitTrigger) { [weak self] in
            self?.exitUpgradeFreeTrialFlowAfterUpgrade()
        }

        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)
        webViewController.navigationItem.leftBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                              target: self,
                                                                              action: #selector(exitUpgradeFreeTrialFlow))
        let navigationController = UINavigationController(rootViewController: webViewController)
        navigationController.isModalInPresentation = true
        present(navigationController, animated: true)
    }

    /// Dismisses the upgrade now web view after the merchants successfully updates their plan.
    ///
    func exitUpgradeFreeTrialFlowAfterUpgrade() {
        removeFreeTrialBanner()
        dismiss(animated: true)

        ServiceLocator.analytics.track(event: .FreeTrial.planUpgradeSuccess(source: .banner))
    }

    /// Dismisses the upgrade now web view when the user abandons the flow.
    ///
    @objc func exitUpgradeFreeTrialFlow() {
        dismiss(animated: true)

        ServiceLocator.analytics.track(event: .FreeTrial.planUpgradeAbandoned(source: .banner))
    }

    func configureDashboardUIContainer() {
        containerView.delegate = self

        // A container view is added to respond to safe area insets from the view controller.
        // This is needed when the child view controller's view has to use a frame-based layout
        // (e.g. when the child view controller is a `ButtonBarPagerTabStripViewController` subclass).
        stackView.addArrangedSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Adds the refresh control to table view manually so that the refresh control always appears below the navigation bar title in
        // large or normal size to be consistent with the products tab.
        // If we do `scrollView.refreshControl = refreshControl`, the refresh control appears in the navigation bar when large title is shown.
        containerView.addSubview(refreshControl)

        NSLayoutConstraint.activate([
            // The width matching constraint is required for the scroll view to be scrollable only vertically.
            containerView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    func configureBottomJetpackBenefitsBanner() {
        bottomJetpackBenefitsBannerController.setActions { [weak self] in
            guard let self, let navigationController = self.navigationController else { return }
            guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
                return
            }
            let coordinator = JetpackSetupCoordinator(site: site,
                                                      rootViewController: navigationController)
            self.jetpackSetupCoordinator = coordinator
            coordinator.showBenefitModal()
            ServiceLocator.analytics.track(event: .jetpackBenefitsBanner(action: .tapped))
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
            self.onDashboardUIUpdate(forced: false, updatedDashboardUI: dashboardUI)
        }.store(in: &subscriptions)
    }

    func observeShowWebViewSheet() {
        viewModel.$showWebViewSheet.sink { [weak self] viewModel in
            guard let self = self else { return }
            guard let viewModel = viewModel else { return }
            self.openWebView(viewModel: viewModel)
        }
        .store(in: &subscriptions)
    }

    private func openWebView(viewModel: WebViewSheetViewModel) {
        let webViewSheet = WebViewSheet(viewModel: viewModel) { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
            Task {
                await self.viewModel.syncAnnouncements(for: self.siteID)
            }
        }
        let hostingController = UIHostingController(rootView: webViewSheet)
        hostingController.presentationController?.delegate = self
        present(hostingController, animated: true, completion: nil)
    }

    /// Subscribes to the trigger to start the Add Product flow for products onboarding
    ///
    private func observeAddProductTrigger() {
        viewModel.addProductTrigger.sink { [weak self] _ in
            self?.startAddProductFlow()
        }
        .store(in: &subscriptions)
    }

    /// Starts the Add Product flow (without switching tabs)
    ///
    private func startAddProductFlow() {
        guard let announcementView, let navigationController else { return }
        let coordinator = AddProductCoordinator(siteID: siteID, sourceView: announcementView, sourceNavigationController: navigationController)
        coordinator.onProductCreated = { [weak self] _ in
            guard let self else { return }
            self.viewModel.announcementViewModel = nil // Remove the products onboarding banner
            Task {
                await self.viewModel.syncAnnouncements(for: self.siteID)
            }
        }
        coordinator.start()
    }

    // This is used so we have a specific type for the view while applying modifiers.
    struct AnnouncementCardWrapper: View {
        let cardView: FeatureAnnouncementCardView

        var body: some View {
            cardView.background(Color(.listForeground(modal: false)))
        }
    }

    func observeAnnouncements() {
        viewModel.$announcementViewModel.sink { [weak self] viewModel in
            guard let self = self else { return }
            Task { @MainActor in
                self.removeAnnouncement()
                guard let viewModel = viewModel else {
                    return
                }

                let cardView = FeatureAnnouncementCardView(
                    viewModel: viewModel,
                    dismiss: { [weak self] in
                        self?.viewModel.announcementViewModel = nil
                    },
                    callToAction: {})
                self.showAnnouncement(AnnouncementCardWrapper(cardView: cardView))
            }
        }
        .store(in: &subscriptions)
    }

    private func removeAnnouncement() {
        guard let announcementView = announcementView else {
            return
        }
        announcementView.removeFromSuperview()
        announcementViewHostingController?.removeFromParent()
        announcementViewHostingController = nil
        self.announcementView = nil
    }

    private func showAnnouncement(_ cardView: AnnouncementCardWrapper) {
        let hostingController = ConstraintsUpdatingHostingController(rootView: cardView)
        guard let uiView = hostingController.view else {
            return
        }
        announcementViewHostingController = hostingController
        announcementView = uiView

        addChild(hostingController)
        let indexAfterHeader = (headerStackView.arrangedSubviews.firstIndex(of: innerStackView) ?? -1) + 1
        headerStackView.insertArrangedSubview(uiView, at: indexAfterHeader)

        hostingController.didMove(toParent: self)
        hostingController.view.layoutIfNeeded()
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
            storeNameLabel.isHidden = true
            return
        }
        shouldShowStoreNameAsSubtitle = true
        storeNameLabel.isHidden = false
        storeNameLabel.text = siteName
    }

    /// Shows or hides the free trial banner.
    ///
    func observeFreeTrialBannerVisibility() {
        viewModel.$freeTrialBannerViewModel.sink { [weak self] viewModel in
            self?.removeFreeTrialBanner()
            if let viewModel {
                self?.addFreeTrialBar(contentText: viewModel.message)
            }
        }.store(in: &subscriptions)
    }
}

private extension DashboardViewController {
    func observeOnboardingVisibility() {
        Publishers.CombineLatest(viewModel.$showOnboarding,
                                 ServiceLocator.stores.site.compactMap { $0 })
        .sink { [weak self] showsOnboarding, site in
            guard let self else { return }
            if showsOnboarding {
                self.showOnboardingCard(site: site)
            } else {
                self.removeOnboardingCard()
            }
        }.store(in: &subscriptions)
    }

    func removeOnboardingCard() {
        guard let onboardingView else {
            return
        }
        onboardingView.removeFromSuperview()
        onboardingHostingController?.removeFromParent()
        onboardingHostingController = nil
        self.onboardingView = nil
    }

    func showOnboardingCard(site: Site) {
        guard let navigationController else {
            return
        }

        if onboardingView != nil {
            removeOnboardingCard()
        }

        let hostingController = StoreOnboardingViewHostingController(viewModel: .init(isExpanded: false,
                                                                                      siteID: site.siteID),
                                                                     navigationController: navigationController,
                                                                     site: site,
                                                                     shareFeedbackAction: { [weak self] in
            // Present survey
            let navigationController = SurveyCoordinatingController(survey: .storeSetup)
            self?.present(navigationController, animated: true, completion: nil)
        })

        guard let uiView = hostingController.view else {
            return
        }
        onboardingHostingController = hostingController
        onboardingView = uiView

        addChild(hostingController)
        addViewBelowHeaderStackView(contentView: uiView)

        hostingController.didMove(toParent: self)
        hostingController.view.layoutIfNeeded()
    }
}

extension DashboardViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController is UIHostingController<WebViewSheet> {
            Task {
                await viewModel.syncAnnouncements(for: siteID)
            }
        }
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
        containerStackView.addArrangedSubview(contentView)
        updatedDashboardUI.didMove(toParent: self)

        // Sets `dashboardUI` after its view is added to the view hierarchy so that observers can update UI based on its view.
        dashboardUI = updatedDashboardUI

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

        addChild(bottomJetpackBenefitsBannerController)
        stackView.addArrangedSubview(banner)
        bottomJetpackBenefitsBannerController.didMove(toParent: self)
    }

    func hideJetpackBenefitsBanner() {
        if isJetpackBenefitsBannerShown {
            stackView.removeArrangedSubview(bottomJetpackBenefitsBannerController.view)
            remove(bottomJetpackBenefitsBannerController)
        }
    }
}

// MARK: - Pull-to-refresh
//
private extension DashboardViewController {
    @objc func pullToRefresh() {
        Task { @MainActor in
            showSpinner(shouldShowSpinner: true)
            await onPullToRefresh()
            showSpinner(shouldShowSpinner: false)
        }
    }

    @MainActor
    func showSpinner(shouldShowSpinner: Bool) {
        if shouldShowSpinner {
            refreshControl.beginRefreshing()
        } else {
            refreshControl.endRefreshing()
        }
    }

    func onPullToRefresh() async {
        ServiceLocator.analytics.track(.dashboardPulledToRefresh)
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { return }
                await self.viewModel.syncAnnouncements(for: self.siteID)
            }
            group.addTask { [weak self] in
                await self?.reloadDashboardUIStatsVersion(forced: true)
            }
            group.addTask { [weak self] in
                await self?.onboardingHostingController?.reloadTasks()
            }
        }
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

                    let isJetpackCPSite = site?.isJetpackCPConnected == true
                    let jetpackSetupForApplicationPassword = site?.isNonJetpackSite == true &&
                        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.jetpackSetupWithApplicationPassword)
                    let shouldShowJetpackBenefitsBanner = (isJetpackCPSite || jetpackSetupForApplicationPassword) && isVisibleFromAppSettings

                    self.updateJetpackBenefitsBannerVisibility(isBannerVisible: shouldShowJetpackBenefitsBanner, contentView: contentView)
                }
                ServiceLocator.stores.dispatch(action)
            }.store(in: &subscriptions)
    }

    func observeNavigationBarHeightForHeaderVisibility() {
        navbarObserverSubscription = navigationController?.navigationBar.publisher(for: \.frame, options: [.new])
            .map({ [weak self] rect in
                // This seems useless given that we're discarding the value later
                // and recalculating within updateHeaderVisibility, but this is an easy
                // way to avoid constant updates with the `removeDuplicates` that follows
                self?.navigationBarIsCollapsed() ?? false
            })
            .removeDuplicates()
            .sink(receiveValue: { [weak self] _ in
                self?.updateHeaderVisibility(animated: true)
            })
    }

    func stopObservingNavigationBarHeightForHeaderVisibility() {
        navbarObserverSubscription?.cancel()
        navbarObserverSubscription = nil
    }
}

// MARK: Constants
private extension DashboardViewController {
    enum Localization {
        static let title = NSLocalizedString(
            "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
        static let upgradeNow = NSLocalizedString("Upgrade Now", comment: "Title for the WebView when upgrading a free trial plan")
    }

    enum Constants {
        static let animationDurationSeconds = CGFloat(0.3)
        static let bannerBottomMargin = CGFloat(8)
        static let horizontalMargin = CGFloat(16)
        static let storeNameTextColor: UIColor = .secondaryLabel
        static let backgroundColor: UIColor = .listForeground(modal: false)
        static let iPhoneCollapsedNavigationBarHeight = CGFloat(44)
        static let iPadCollapsedNavigationBarHeight = CGFloat(50)
        static let tabStripSpacing = CGFloat(12)
        static let headerStackViewSpacing = CGFloat(4)
    }
}
