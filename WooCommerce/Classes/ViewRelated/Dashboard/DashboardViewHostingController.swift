import SwiftUI
import struct Yosemite.Site

/// Hosting view for `DashboardView`
///
final class DashboardViewHostingController: UIHostingController<DashboardView> {

    private let viewModel: DashboardViewModel
    private var storeOnboardingCoordinator: StoreOnboardingCoordinator?

    init(siteID: Int64) {
        let viewModel = DashboardViewModel(siteID: siteID)
        self.viewModel = viewModel
        super.init(rootView: DashboardView(viewModel: viewModel))
        configureTabBarItem()
        configureStoreOnboarding()
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerUserActivity()
    }
}

// MARK: Private helpers
private extension DashboardViewHostingController {
    func configureTabBarItem() {
        tabBarItem.image = .statsAltImage
        tabBarItem.title = Localization.title
        tabBarItem.accessibilityIdentifier = "tab-bar-my-store-item"
    }

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
