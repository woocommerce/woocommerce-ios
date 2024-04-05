import Combine
import SwiftUI
import struct Yosemite.Site

/// Hosting view for `DashboardView`
///
final class DashboardViewHostingController: UIHostingController<DashboardView> {

    private let viewModel: DashboardViewModel
    private let usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter
    private var storeOnboardingCoordinator: StoreOnboardingCoordinator?
    private var blazeCampaignCreationCoordinator: BlazeCampaignCreationCoordinator?
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?
    private var modalJustInTimeMessageHostingController: ConstraintsUpdatingHostingController<JustInTimeMessageModal_UIKit>?

    /// Presenter for the privacy choices banner
    private lazy var privacyBannerPresenter = PrivacyBannerPresenter()

    private var subscriptions: Set<AnyCancellable> = []

    init(siteID: Int64) {
        let viewModel = DashboardViewModel(siteID: siteID)
        let usageTracksEventEmitter = StoreStatsUsageTracksEventEmitter()
        self.viewModel = viewModel
        self.usageTracksEventEmitter = usageTracksEventEmitter

        super.init(rootView: DashboardView(viewModel: viewModel, usageTracksEventEmitter: usageTracksEventEmitter))

        configureTabBarItem()
        configureStoreOnboarding()
        configureBlazeSection()
        configureJetpackBenefitBanner()

    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerUserActivity()
        presentPrivacyBannerIfNeeded()
        observeModalJustInTimeMessages()

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

    private func observeModalJustInTimeMessages() {
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
}

// MARK: Store onboarding
private extension DashboardViewHostingController {
    func configureStoreOnboarding() {
        rootView.onboardingTaskTapped = { [weak self] site, task in
            guard let self, !task.isComplete else { return }
            updateStoreOnboardingCoordinatorIfNeeded(with: site)
            ServiceLocator.analytics.track(event: .StoreOnboarding.storeOnboardingTaskTapped(task: task.type))
            storeOnboardingCoordinator?.start(task: task)
        }

        rootView.viewAllOnboardingTasksTapped = { [weak self] site in
            guard let self else { return }
            updateStoreOnboardingCoordinatorIfNeeded(with: site)
            storeOnboardingCoordinator?.start()
        }

        rootView.onboardingShareFeedbackAction = { [weak self] in
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
        }, onUpgradePlan: {
            // TODO: maybe remove this
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
            let controller = BlazeCampaignListHostingController(viewModel: .init(siteID: viewModel.siteID))
            navigationController.show(controller, sender: self)
        }

        rootView.createBlazeCampaignTapped = { [weak self] productID in
            guard let self, let navigationController else { return }
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
        Task {
            await viewModel.blazeCampaignDashboardViewModel.reload()
        }
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
