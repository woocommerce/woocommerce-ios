import Combine
import SwiftUI
import WordPressUI
import struct Yosemite.Site

/// Hosting view for `DashboardView`
///
final class DashboardViewHostingController: UIHostingController<DashboardView> {

    private let viewModel: DashboardViewModel
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter
    private var storeOnboardingCoordinator: StoreOnboardingCoordinator?
    private var blazeCampaignCreationCoordinator: BlazeCampaignCreationCoordinator?
    private var googleAdsCampaignCoordinator: GoogleAdsCampaignCoordinator?
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?
    private var modalJustInTimeMessageHostingController: ConstraintsUpdatingHostingController<JustInTimeMessageModal_UIKit>?
    private var isAppActive = true

    /// Presenter for the privacy choices banner
    private lazy var privacyBannerPresenter = PrivacyBannerPresenter()

    /// Information alert for custom range tab redaction
    ///
    private lazy var fancyAlert: FancyAlertViewController = {
        let alert = FancyAlertViewController.makeCustomRangeRedactionInformationAlert()
        alert.modalPresentationStyle = .custom
        alert.transitioningDelegate = AppDelegate.shared.tabBarController
        return alert
    }()

    private var subscriptions: Set<AnyCancellable> = []

    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    init(siteID: Int64) {
        let usageTracksEventEmitter = StoreStatsUsageTracksEventEmitter()
        let viewModel = DashboardViewModel(siteID: siteID, usageTracksEventEmitter: usageTracksEventEmitter)
        self.viewModel = viewModel
        self.usageTracksEventEmitter = usageTracksEventEmitter

        super.init(rootView: DashboardView(viewModel: viewModel))

        configureTabBarItem()
        configureStoreOnboarding()
        configureBlazeSection()
        configureJetpackBenefitBanner()
        configureStorePerformanceView()
        configureInboxCard()
        configureMostActiveCouponsView()
        configureLastOrdersView()
        configureReviewsCard()
        configureGoogleAdsCard()
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ServiceLocator.analytics.track(.dashboardLoaded)

        registerUserActivity()
        presentPrivacyBannerIfNeeded()
        observeModalJustInTimeMessages()
        registerForSystemNotifications()

        Task {
            await viewModel.reloadAllData()
        }
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }
}

// MARK: Private helpers
private extension DashboardViewHostingController {
    func configureTabBarItem() {
        tabBarItem.image = .statsAltImage
        tabBarItem.title = Localization.title
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }

    /// Presents the privacy banner if needed.
    ///
    func presentPrivacyBannerIfNeeded() {
        privacyBannerPresenter.presentIfNeeded(from: self)
    }

    func observeModalJustInTimeMessages() {
        viewModel.$modalJustInTimeMessageViewModel.sink { [weak self] viewModel in
            guard let viewModel, let self else {
                return
            }

            let modalController = ConstraintsUpdatingHostingController(
                rootView: JustInTimeMessageModal_UIKit(
                    onDismiss: { [weak self] in
                        self?.dismiss(animated: true)
                    },
                    viewModel: viewModel))

            modalJustInTimeMessageHostingController = modalController
            modalController.view.backgroundColor = .clear
            modalController.modalPresentationStyle = .overFullScreen
            present(modalController, animated: true)
        }
        .store(in: &subscriptions)
    }

    func configureStorePerformanceView() {
        rootView.onCustomRangeRedactedViewTap = { [weak self] in
            guard let self else { return }
            present(fancyAlert, animated: true)
        }

        rootView.onViewAllAnalytics = { [weak self] siteID, siteTimeZone, timeRange in
            guard let self else { return }
            ServiceLocator.analytics.track(event: .AnalyticsHub.seeMoreAnalyticsTapped())
            let analyticsHubVC = AnalyticsHubHostingViewController(siteID: siteID,
                                                                   timeZone: siteTimeZone,
                                                                   timeRange: timeRange,
                                                                   usageTracksEventEmitter: usageTracksEventEmitter)
            show(analyticsHubVC, sender: self)
        }
    }

    func configureInboxCard() {
        rootView.onShowAllInboxMessages = { [weak self] in
            guard let self else { return }
            let inboxViewModel = InboxViewModel(siteID: viewModel.siteID)
            let hostingController = UIHostingController(rootView: Inbox(viewModel: inboxViewModel))
            show(hostingController, sender: self)
        }
    }

    func registerForSystemNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDeactivation),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppActivation),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    /// Tracks when the app goes to background.
    ///
    @objc func handleAppDeactivation() {
        isAppActive = false
    }

    /// Call on `viewModel.onViewAppear` when the view appears due to coming from the background.
    ///
    @objc func handleAppActivation() {
        // Avoid reloading if the view is not visible. The refresh will be handled in
        // `viewWillAppear/onAppear` instead.
        guard !isAppActive, viewIfLoaded?.window != nil else { return }
        isAppActive = true
        Task {
            await viewModel.onViewAppear()
        }
    }
}

// MARK: Store onboarding
private extension DashboardViewHostingController {
    func configureStoreOnboarding() {
        rootView.onboardingTaskTapped = { [weak self] site, task in
            guard let self, !task.isComplete else { return }
            updateStoreOnboardingCoordinatorIfNeeded(with: site)
            ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .onboarding))
            ServiceLocator.analytics.track(event: .StoreOnboarding.storeOnboardingTaskTapped(task: task.type))
            storeOnboardingCoordinator?.start(task: task)
        }

        rootView.viewAllOnboardingTasksTapped = { [weak self] site in
            guard let self else { return }
            ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .onboarding))
            updateStoreOnboardingCoordinatorIfNeeded(with: site)
            storeOnboardingCoordinator?.start()
        }

        rootView.onboardingShareFeedbackAction = { [weak self] in
            ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .onboarding))
            let navigationController = SurveyCoordinatingController(survey: .storeSetup)
            self?.present(navigationController, animated: true, completion: nil)
        }
    }

    func updateStoreOnboardingCoordinatorIfNeeded(with site: Site) {
        guard let navigationController, storeOnboardingCoordinator?.site != site else {
            return
        }
        let coordinator = StoreOnboardingCoordinator(navigationController: navigationController,
                                                     site: site,
                                                     onTaskCompleted: { [weak self] task in
            self?.reloadOnboardingTask()
            ServiceLocator.analytics.track(event: .StoreOnboarding.storeOnboardingTaskCompleted(task: task))
        }, reloadTasks: { [weak self] in
            self?.reloadOnboardingTask()
        })
        self.storeOnboardingCoordinator = coordinator
    }

    func reloadOnboardingTask() {
        Task {
            await viewModel.storeOnboardingViewModel.reloadTasks()
        }
    }
}

// MARK: Blaze section
private extension DashboardViewHostingController {
    func configureBlazeSection() {
        rootView.showAllBlazeCampaignsTapped = { [weak self] in
            guard let self, let navigationController else { return }
            ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .blaze))

            let controller = BlazeCampaignListHostingController(viewModel: .init(siteID: viewModel.siteID))
            navigationController.show(controller, sender: self)
        }

        rootView.createBlazeCampaignTapped = { [weak self] productID in
            guard let self, let navigationController else { return }
            ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .blaze))

            let coordinator = BlazeCampaignCreationCoordinator(
                siteID: viewModel.blazeCampaignDashboardViewModel.siteID,
                siteURL: viewModel.blazeCampaignDashboardViewModel.siteURL,
                productID: productID,
                source: .myStoreSection,
                shouldShowIntro: viewModel.blazeCampaignDashboardViewModel.shouldShowIntroView,
                navigationController: navigationController,
                onCampaignCreated: handlePostCreation
            )
            coordinator.start()
            self.blazeCampaignCreationCoordinator = coordinator
        }
    }

    /// Reloads data.
    func handlePostCreation() {
        viewModel.blazeCampaignDashboardViewModel.didCreateCampaign()
    }
}

// MARK: Jetpack benefit banner
private extension DashboardViewHostingController {
    func configureJetpackBenefitBanner() {
        rootView.jetpackBenefitsBannerTapped = { [weak self] site in
            guard let self, let navigationController else {
                return
            }
            let coordinator = JetpackSetupCoordinator(site: site,
                                                      rootViewController: navigationController)
            jetpackSetupCoordinator = coordinator
            coordinator.showBenefitModal()
        }
    }
}

// MARK: Most active coupons
private extension DashboardViewHostingController {
    func configureMostActiveCouponsView() {
        rootView.onViewAllCoupons = { [weak self] in
            guard let self else { return }
            let couponsVC = EnhancedCouponListViewController(siteID: viewModel.siteID)
            show(couponsVC, sender: self)
        }

        rootView.onViewCouponDetail = { [weak self] coupon in
            guard let self else { return }
            let detailsViewModel = CouponDetailsViewModel(coupon: coupon,
                                                          onUpdate: { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.viewModel.mostActiveCouponsViewModel.reloadData()
                }
            },
                                                          onDeletion: { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.viewModel.mostActiveCouponsViewModel.reloadData()
                }
                self.navigationController?.popViewController(animated: true)
                let notice = Notice(title: EnhancedCouponListViewController.Localization.couponDeleted, feedbackType: .success)
                self.noticePresenter.enqueue(notice: notice)
            })
            let detailVC = CouponDetailsHostingController(viewModel: detailsViewModel)
            show(detailVC, sender: self)
        }
    }
}

// MARK: Last orders
private extension DashboardViewHostingController {
    func configureLastOrdersView() {
        rootView.onViewAllOrders = {
            MainTabBarController.switchToOrdersTab()
        }

        rootView.onViewOrderDetail = { [weak self] order in
            guard let self else { return }
            MainTabBarController.navigateToOrderDetails(with: order.orderID, siteID: viewModel.siteID)
        }
    }
}

// MARK: Reviews card
private extension DashboardViewHostingController {
    func configureReviewsCard() {
        rootView.onViewReviewDetail = { [weak self] review in
            guard let self else { return }
            let viewController = ReviewDetailsViewController(productReview: review.review,
                                                             product: review.product,
                                                             notification: review.notification)
            show(viewController, sender: self)
        }

        rootView.onViewAllReviews = { [weak self] in
            guard let self else { return }
            let viewController = ReviewsViewController(siteID: viewModel.siteID)
            show(viewController, sender: self)
        }
    }
}

// MARK: Google Ads campaigns
private extension DashboardViewHostingController {
    func configureGoogleAdsCard() {
        rootView.onCreateNewGoogleAdsCampaign = { [weak self] in
            self?.startGoogleAdsCampaignCoordinator(forCampaignCreation: true)
        }

        rootView.onShowAllGoogleAdsCampaigns = { [weak self] in
            self?.startGoogleAdsCampaignCoordinator(forCampaignCreation: false)
        }
    }

    func startGoogleAdsCampaignCoordinator(forCampaignCreation: Bool) {
        guard let site = viewModel.stores.sessionManager.defaultSite,
              let navigationController else {
            return
        }

        let coordinator = GoogleAdsCampaignCoordinator(
            siteID: viewModel.siteID,
            siteAdminURL: site.adminURLWithFallback()?.absoluteString ?? site.adminURL,
            source: .myStore,
            shouldStartCampaignCreation: forCampaignCreation,
            shouldAuthenticateAdminPage: viewModel.stores.shouldAuthenticateAdminPage(for: site),
            navigationController: navigationController,
            onCompletion: { [weak self] createdNewCampaign in
                if createdNewCampaign {
                    self?.viewModel.googleAdsDashboardCardViewModel.reloadCard()
                }
            }
        )
        coordinator.start()
        googleAdsCampaignCoordinator = coordinator

        let hasCampaigns = viewModel.googleAdsDashboardCardViewModel.hasPaidCampaigns
        ServiceLocator.analytics.track(event: .GoogleAds.entryPointTapped(
            source: .myStore,
            type: forCampaignCreation ? .campaignCreation : .dashboard,
            hasCampaigns: hasCampaigns
        ))
    }
}

private extension DashboardViewHostingController {
    enum Localization {
        static let title = NSLocalizedString(
            "dashboardViewHostingController.title",
            value: "My store",
            comment: "Title of the bottom tab item that presents the user's store dashboard, and default title for the store dashboard"
        )
    }
}

// MARK: - SearchableActivity Conformance
extension DashboardViewHostingController: SearchableActivityConvertible {
    var activityType: String {
        return WooActivityType.dashboard.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("My Store", comment: "Title of the 'My Store' tab - used for spotlight indexing on iOS.")
    }

    var activityDescription: String? {
        return NSLocalizedString("See at a glance which products are winning.",
                                 comment: "Description of the 'My Store' screen - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("woocommerce, my store, today, this week, this month, this year," +
                                              "orders, visitors, conversion, top conversion, items sold",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Dashboard' tab.")
        return keyWordString.setOfTags()
    }
}
