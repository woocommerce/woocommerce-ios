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
        let verticalMargin = Constants.verticalMargin
        view.layoutMargins = UIEdgeInsets(top: 0, left: horizontalMargin, bottom: verticalMargin, right: horizontalMargin)
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

    private lazy var shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareStore))

    /// Stores an animator for showing/hiding the header view while there is an animation in progress
    /// so we can interrupt and reverse if needed
    private var headerAnimator: UIViewPropertyAnimator?

    /// Top banner that shows an error if there is a problem loading data
    ///
    private var topBannerView: TopBannerView?

    private var announcementViewHostingController: ConstraintsUpdatingHostingController<AnnouncementCardWrapper>?

    private var announcementView: UIView?

    private var modalJustInTimeMessageHostingController: ConstraintsUpdatingHostingController<JustInTimeMessageModal_UIKit>?
    private var localAnnouncementModalHostingController: ConstraintsUpdatingHostingController<LocalAnnouncementModal_UIKit>?

    /// Onboarding card.
    private var onboardingHostingController: StoreOnboardingViewHostingController?
    private var onboardingView: UIView?

    /// Hosting controller for the banner to highlight the Blaze feature.
    ///
    private var blazeBannerHostingController: BlazeBannerHostingController?

    /// Hosting controller for the Blaze Campaign View.
    ///
    private var blazeCampaignHostingController: BlazeCampaignDashboardViewHostingController?

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

    private let viewModel: DashboardViewModel

    private let usageTracksEventEmitter = StoreStatsUsageTracksEventEmitter()

    private var subscriptions = Set<AnyCancellable>()
    private var navbarObserverSubscription: AnyCancellable?

    /// Store plan banner presentation handler.
    ///
    private var storePlanBannerPresenter: StorePlanBannerPresenter?

    /// Presenter for the privacy choices banner
    ///
    private lazy var privacyBannerPresenter = PrivacyBannerPresenter()

    // MARK: View Lifecycle

    init(siteID: Int64) {
        self.siteID = siteID
        self.viewModel = .init(siteID: siteID)
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
        observeModalJustInTimeMessages()
        observeLocalAnnouncement()
        observeShowWebViewSheet()
        observeAddProductTrigger()
        observeOnboardingVisibility()
        observeBlazeCampaignViewVisibility()
        observeBlazeBannerVisibility()
        configureStorePlanBannerPresenter()
        presentPrivacyBannerIfNeeded()

        Task { @MainActor in
            await viewModel.syncAnnouncements(for: siteID)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset title to prevent it from being empty right after login
        configureTitle()

        storePlanBannerPresenter?.reloadBannerVisibility()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateHeaderVisibility(animated: false)
        observeNavigationBarHeightForHeaderVisibility()

        Task {
            await viewModel.uploadProfilerAnswers()
        }
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
        configureShareButton()
    }

    func configureTabBarItem() {
        tabBarItem.image = .statsAltImage
        tabBarItem.title = Localization.title
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }

    func configureTitle() {
        navigationItem.title = Localization.title
    }

    func configureShareButton() {
        guard viewModel.siteURLToShare != nil else {
            return
        }
        navigationItem.rightBarButtonItem = shareButton
    }

    @objc
    func shareStore() {
        guard let url = viewModel.siteURLToShare else {
            return
        }
        SharingHelper.shareURL(url: url, from: shareButton, in: self)
        ServiceLocator.analytics.track(.dashboardShareStoreButtonTapped)
    }

    func configureContainerStackView() {
        containerStackView.axis = .vertical
        containerStackView.spacing = Constants.containerStackViewSpacing
        containerStackView.backgroundColor = .listBackground
        containerView.addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinSubviewToAllEdges(containerStackView)
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalTo: containerStackView.widthAnchor)
        ])
    }

    func configureHeaderStackView() {
        configureSubtitle()
        containerStackView.addArrangedSubview(headerStackView)
    }

    func configureSubtitle() {
        storeNameLabel.text = ServiceLocator.stores.sessionManager.defaultSite?.name ?? Localization.title
        storeNameLabel.textColor = Constants.storeNameTextColor
        innerStackView.addArrangedSubview(storeNameLabel)
        headerStackView.addArrangedSubview(innerStackView)
    }

    func addViewBelowHeaderStackView(contentView: UIView) {
        let indexAfterHeader = (containerStackView.arrangedSubviews.firstIndex(of: headerStackView) ?? -1) + 1
        containerStackView.insertArrangedSubview(contentView, at: indexAfterHeader)
    }

    func addViewBelowOnboardingCard(_ contentView: UIView) {
        let indexOfHeader = containerStackView.arrangedSubviews.firstIndex(of: headerStackView) ?? -1
        let indexAfterOnboardingCard: Int = {
            if let onboardingView {
                return (containerStackView.arrangedSubviews.firstIndex(of: onboardingView) ?? indexOfHeader) + 1
            }
            return indexOfHeader + 1
        }()
        containerStackView.insertArrangedSubview(contentView, at: indexAfterOnboardingCard)
    }

    func configureStackView() {
        stackView.axis = .vertical
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(stackView)
    }

    func configureStorePlanBannerPresenter() {
        self.storePlanBannerPresenter =  StorePlanBannerPresenter(viewController: self,
                                                                  containerView: stackView,
                                                                  siteID: siteID) { [weak self] bannerHeight in
            self?.containerView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bannerHeight, right: 0)
        }
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
            guard let self else { return }
            guard let viewModel else { return }
            Task { @MainActor in
                await self.dismissPossibleModals()
                self.openWebView(viewModel: viewModel)
            }
        }
        .store(in: &subscriptions)
    }

    private func openWebView(viewModel: WebViewSheetViewModel) {
        let webViewSheet = WebViewSheet(viewModel: viewModel) { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
            self.maybeSyncAnnouncementsAfterWebViewDismissed()
        }
        let hostingController = UIHostingController(rootView: webViewSheet)
        hostingController.presentationController?.delegate = self
        present(hostingController, animated: true, completion: nil)
    }

    private func maybeSyncAnnouncementsAfterWebViewDismissed() {
        // If the web view was opened from a modal JITM, it was dismissed before the webview
        // was presented. Syncing in that situation would result in it showing again.
        if self.viewModel.modalJustInTimeMessageViewModel == nil {
            Task {
                await self.viewModel.syncAnnouncements(for: self.siteID)
            }
        }
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
        let coordinator = AddProductCoordinator(siteID: siteID,
                                                source: .productOnboarding,
                                                sourceView: announcementView,
                                                sourceNavigationController: navigationController,
                                                isFirstProduct: true)
        coordinator.onProductCreated = { [weak self] _ in
            guard let self else { return }
            self.viewModel.announcementViewModel = nil // Remove the products onboarding banner
            Task {
                await self.viewModel.syncAnnouncements(for: self.siteID)
            }
        }
        coordinator.start()
    }

    /// Invoked when the local announcement CTA is tapped.
    private func onLocalAnnouncementAction(_ announcement: LocalAnnouncement) {
        switch announcement {
            case .productDescriptionAI:
                startAddProductFlowFromProductDescriptionAIModal()
        }
    }

    /// Starts the Add Product flow to showcase the product description AI feature.
    private func startAddProductFlowFromProductDescriptionAIModal() {
        AppDelegate.shared.tabBarController?.navigateToTabWithNavigationController(.products, animated: true) { [weak self] navigationController in
            guard let self else { return }
            let coordinator = AddProductCoordinator(siteID: self.siteID,
                                                    source: .productDescriptionAIAnnouncementModal,
                                                    sourceView: nil,
                                                    sourceNavigationController: navigationController,
                                                    isFirstProduct: true)
            coordinator.start()
        }
    }

    // This is used so we have a specific type for the view while applying modifiers.
    struct AnnouncementCardWrapper: View {
        let cardView: FeatureAnnouncementCardView

        var body: some View {
            cardView.background(Color(.listForeground(modal: false)))
        }
    }

    func observeAnnouncements() {
        Publishers.CombineLatest(viewModel.$announcementViewModel,
                                 viewModel.$showOnboarding)
        .sink { [weak self] viewModel, showOnboarding in
            guard let self = self else { return }
            Task { @MainActor in
                self.removeAnnouncement()
                guard let viewModel = viewModel else {
                    return
                }

                guard !showOnboarding else {
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

    private func observeModalJustInTimeMessages() {
        viewModel.$modalJustInTimeMessageViewModel.sink { [weak self] viewModel in
            guard let viewModel = viewModel else {
                return
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.dismissPossibleModals()
                let modalController = ConstraintsUpdatingHostingController(
                    rootView: JustInTimeMessageModal_UIKit(
                        onDismiss: {
                            self.dismiss(animated: true)
                        },
                        viewModel: viewModel))

                self.modalJustInTimeMessageHostingController = modalController
                modalController.view.backgroundColor = .clear
                modalController.modalPresentationStyle = .overFullScreen
                self.present(modalController, animated: true)
            }
        }
        .store(in: &subscriptions)
    }

    private func observeLocalAnnouncement() {
        viewModel.$localAnnouncementViewModel
            .compactMap { $0 }
            .asyncMap { [weak self] viewModel in
                await self?.dismissPossibleModals()
                viewModel.actionTapped = { [weak self] announcement in
                    self?.onLocalAnnouncementAction(announcement)
                }
                return ConstraintsUpdatingHostingController(
                    rootView: LocalAnnouncementModal_UIKit(
                        onDismiss: {
                            self?.dismiss(animated: true)
                        },
                        viewModel: viewModel))
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] modalController in
                guard let self else { return }
                self.localAnnouncementModalHostingController = modalController
                modalController.view.backgroundColor = .clear
                modalController.modalPresentationStyle = .overFullScreen
                self.present(modalController, animated: true)
            }
            .store(in: &subscriptions)
    }

    private func dismissPossibleModals() async {
        await dismissModalJustInTimeMessage()
        await dismissLocalAnnouncementModal()
    }

    private func dismissModalJustInTimeMessage() async {
        guard modalJustInTimeMessageHostingController != nil else {
            return
        }
        await withCheckedContinuation { continuation in
            dismiss(animated: true) { [weak self] in
                self?.modalJustInTimeMessageHostingController = nil
                continuation.resume()
            }
        }
    }

    private func dismissLocalAnnouncementModal() async {
        guard localAnnouncementModalHostingController != nil else {
            return
        }
        await withCheckedContinuation { continuation in
            dismiss(animated: true) { [weak self] in
                self?.localAnnouncementModalHostingController = nil
                continuation.resume()
            }
        }
    }

    /// Display the error banner at the top of the dashboard content (below the site title)
    ///
    func showTopBannerView(for error: Error) {
        if topBannerView != nil { // Clear the top banner first, if needed
            hideTopBannerView()
        }

        let errorBanner = ErrorTopBannerFactory.createTopBanner(for: error,
                                                                expandedStateChangeHandler: {},
                                                                onTroubleshootButtonPressed: { [weak self] in
            guard let self else { return }
            WebviewHelper.launch(ErrorTopBannerFactory.troubleshootUrl(for: error), with: self)
        },
                                                                onContactSupportButtonPressed: { [weak self] in
            guard let self else { return }
            let supportForm = SupportFormHostingController(viewModel: .init())
            supportForm.show(from: self)
        })

        // Configure header stack view
        topBannerView = errorBanner
        headerStackView.addArrangedSubviews([errorBanner, spacerView])
    }

    /// Hide the error banner
    ///
    func hideTopBannerView() {
        topBannerView?.removeFromSuperview()
        spacerView.removeFromSuperview()
        topBannerView = nil
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
}

private extension DashboardViewController {
    func observeOnboardingVisibility() {
        Publishers.CombineLatest(viewModel.$showOnboarding.removeDuplicates(),
                                 ServiceLocator.stores.site.compactMap { $0 }.removeDuplicates())
        .sink { [weak self] showsOnboarding, site in
            guard let self else { return }
            if showsOnboarding {
                self.showOnboardingCard(site: site)
            } else {
                self.removeOnboardingCard()
                ServiceLocator.startupWaitingTimeTracker.end(action: .loadOnboardingTasks)
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

        let hostingController = StoreOnboardingViewHostingController(viewModel: viewModel.storeOnboardingViewModel,
                                                                     navigationController: navigationController,
                                                                     site: site,
                                                                     onUpgradePlan: { [weak self] in
            guard let self else { return }
            self.storePlanBannerPresenter?.reloadBannerVisibility()
        },
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


    /// Presents the privacy banner if needed.
    ///
    func presentPrivacyBannerIfNeeded() {
        privacyBannerPresenter.presentIfNeeded(from: self)
    }
}

// MARK: - Blaze campaign view
extension DashboardViewController {
    func observeBlazeCampaignViewVisibility() {
        viewModel.$showBlazeCampaignView.removeDuplicates()
            .sink { [weak self] showBlazeCampaignView in
                guard let self else { return }
                if showBlazeCampaignView {
                    self.showBlazeCampaignView()
                } else {
                    self.removeBlazeCampaignView()
                }
            }
            .store(in: &subscriptions)

        Task { @MainActor [weak self] in
            await self?.viewModel.reloadBlazeCampaignView()
        }
    }

    func showBlazeCampaignView() {
        if blazeCampaignHostingController != nil {
            removeBlazeCampaignView()
        }
        let hostingController = BlazeCampaignDashboardViewHostingController(
            viewModel: viewModel.blazeCampaignDashboardViewModel,
            parentNavigationController: navigationController
        )
        guard let campaignView = hostingController.view else {
            return
        }
        campaignView.translatesAutoresizingMaskIntoConstraints = false
        addViewBelowOnboardingCard(campaignView)
        addChild(hostingController)
        hostingController.didMove(toParent: self)
        blazeCampaignHostingController = hostingController
    }

    func removeBlazeCampaignView() {
        guard let blazeCampaignHostingController,
              blazeCampaignHostingController.parent == self else { return }
        blazeCampaignHostingController.willMove(toParent: nil)
        blazeCampaignHostingController.view.removeFromSuperview()
        blazeCampaignHostingController.removeFromParent()
        self.blazeCampaignHostingController = nil
    }
}

// MARK: - Blaze banner
extension DashboardViewController {
    func observeBlazeBannerVisibility() {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.optimizedBlazeExperience) == false else {
            return
        }
        viewModel.$showBlazeBanner.removeDuplicates()
            .sink { [weak self] showsBlazeBanner in
                guard let self else { return }
                if showsBlazeBanner {
                    self.showBlazeBanner()
                } else {
                    self.removeBlazeBanner()
                }
            }
            .store(in: &subscriptions)

        Task { @MainActor in
            await viewModel.updateBlazeBannerVisibility()
        }
    }

    func showBlazeBanner() {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return
        }
        if blazeBannerHostingController != nil {
            removeBlazeBanner()
        }
        let hostingController = BlazeBannerHostingController(
            site: site,
            entryPoint: .myStore,
            containerViewController: self,
            dismissHandler: { [weak self] in
            self?.viewModel.hideBlazeBanner()
        })
        guard let bannerView = hostingController.view else {
            return
        }
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        addViewBelowOnboardingCard(bannerView)
        addChild(hostingController)
        hostingController.didMove(toParent: self)
        blazeBannerHostingController = hostingController
    }

    func removeBlazeBanner() {
        guard let blazeBannerHostingController,
              blazeBannerHostingController.parent == self else { return }
        blazeBannerHostingController.willMove(toParent: nil)
        blazeBannerHostingController.view.removeFromSuperview()
        blazeBannerHostingController.removeFromParent()
        self.blazeBannerHostingController = nil
    }
}

extension DashboardViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController is UIHostingController<WebViewSheet> {
            maybeSyncAnnouncementsAfterWebViewDismissed()
        }
    }
}

// MARK: - Updates
//
private extension DashboardViewController {
    func onDashboardUIUpdate(forced: Bool, updatedDashboardUI: DashboardUI) {
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

        updatedDashboardUI.displaySyncingError = { [weak self] error in
            self?.showTopBannerView(for: error)
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
        hideTopBannerView() // Hide error banner optimistically on pull to refresh
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { return }
                await self.viewModel.syncAnnouncements(for: self.siteID)
            }
            group.addTask { [weak self] in
                await self?.reloadDashboardUIStatsVersion(forced: true)
            }
            group.addTask { [weak self] in
                await self?.viewModel.reloadStoreOnboardingTasks()
            }
            group.addTask { [weak self] in
                await self?.viewModel.updateBlazeBannerVisibility()
            }
            group.addTask { [weak self] in
                await self?.viewModel.reloadBlazeCampaignView()
            }
        }
    }
}

// MARK: - Private Helpers
//
private extension DashboardViewController {
    func observeSiteForUIUpdates() {
        ServiceLocator.stores.site.sink { [weak self] site in
            guard let self = self else { return }
            // We always want to update UI based on the latest site only if it matches the view controller's site ID.
            // When switching stores, this is triggered on the view controller of the previous site ID.
            guard let site = site, site.siteID == self.siteID else {
                return
            }
            self.updateUI(site: site)
            self.trackDeviceTimezoneDifferenceWithStore(siteGMTOffset: site.gmtOffset)
            Task { @MainActor [weak self] in
                await self?.viewModel.updateBlazeBannerVisibility()
            }
            Task { @MainActor [weak self] in
                await self?.viewModel.reloadBlazeCampaignView()
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
                    let isNonJetpackSite = site?.isNonJetpackSite == true
                    let shouldShowJetpackBenefitsBanner = (isJetpackCPSite || isNonJetpackSite) && isVisibleFromAppSettings

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

    func trackDeviceTimezoneDifferenceWithStore(siteGMTOffset: Double) {
        viewModel.trackStatsTimezone(localTimezone: TimeZone.current, siteGMTOffset: siteGMTOffset)
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
        static let animationDurationSeconds = CGFloat(0.3)
        static let bannerBottomMargin = CGFloat(8)
        static let horizontalMargin = CGFloat(16)
        static let verticalMargin = CGFloat(16)
        static let storeNameTextColor: UIColor = .secondaryLabel
        static let backgroundColor: UIColor = .listForeground(modal: false)
        static let iPhoneCollapsedNavigationBarHeight = CGFloat(44)
        static let iPadCollapsedNavigationBarHeight = CGFloat(50)
        static let tabStripSpacing = CGFloat(12)
        static let headerStackViewSpacing = CGFloat(4)
        static let containerStackViewSpacing = CGFloat(16)
    }
}
