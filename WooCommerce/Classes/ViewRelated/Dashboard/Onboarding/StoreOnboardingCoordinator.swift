import Foundation
import SwiftUI
import UIKit
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// Coordinates navigation for store onboarding.
final class StoreOnboardingCoordinator: Coordinator {
    typealias TaskType = StoreOnboardingTask.TaskType

    let navigationController: UINavigationController

    private var storeDetailsCoordinator: StoreOnboardingStoreDetailsCoordinator?
    private var addProductCoordinator: AddProductCoordinator?
    private var domainSettingsCoordinator: DomainSettingsCoordinator?
    private var launchStoreCoordinator: StoreOnboardingLaunchStoreCoordinator?
    private var paymentsSetupCoordinator: StoreOnboardingPaymentsSetupCoordinator?

    private let site: Site
    private let onTaskCompleted: (_ task: TaskType) -> Void
    private let reloadTasks: () -> Void
    private let onUpgradePlan: (() -> Void)?

    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = navigationController
        return noticePresenter
    }()

    init(navigationController: UINavigationController,
         site: Site,
         onTaskCompleted: @escaping (_ task: TaskType) -> Void,
         reloadTasks: @escaping () -> Void,
         onUpgradePlan: (() -> Void)? = nil) {
        self.navigationController = navigationController
        self.site = site
        self.onTaskCompleted = onTaskCompleted
        self.reloadTasks = reloadTasks
        self.onUpgradePlan = onUpgradePlan
    }

    /// Navigates to the fullscreen store onboarding view.
    func start() {
        let onboardingNavigationController = UINavigationController()
        let onboardingViewController = StoreOnboardingViewHostingController(viewModel: .init(siteID: site.siteID,
                                                                                             isExpanded: true),
                                                                            navigationController: onboardingNavigationController,
                                                                            site: site,
                                                                            onUpgradePlan: onUpgradePlan)
        onboardingNavigationController.pushViewController(onboardingViewController, animated: false)
        navigationController.present(onboardingNavigationController, animated: true)
    }

    /// Navigates to complete an onboarding task.
    /// - Parameter task: the task to complete.
    func start(task: StoreOnboardingTask) {
        switch task.type {
        case .storeDetails:
            showStoreDetails()
        case .addFirstProduct:
            addProduct()
        case .customizeDomains:
            showCustomDomains()
        case .launchStore:
            launchStore(task: task)
        case .woocommercePayments:
            showWCPaySetup()
        case .payments:
            showPaymentsSetup()
        case .storeName:
            showStoreNameSetup()
        case .unsupported:
            assertionFailure("Unexpected onboarding task: \(task)")
        }
    }
}

private extension StoreOnboardingCoordinator {
    func showStoreDetails() {
        let coordinator = StoreOnboardingStoreDetailsCoordinator(site: site,
                                                                 navigationController: navigationController,
                                                                 onDismiss: { [weak self] in
            self?.reloadTasks()
        })
        self.storeDetailsCoordinator = coordinator
        coordinator.start()
    }

    func addProduct() {
        let coordinator = AddProductCoordinator(siteID: site.siteID,
                                                source: .storeOnboarding,
                                                sourceView: nil,
                                                sourceNavigationController: navigationController,
                                                isFirstProduct: true)
        self.addProductCoordinator = coordinator
        coordinator.onProductCreated = { [weak self] _ in
            self?.onTaskCompleted(.addFirstProduct)
        }
        coordinator.start()
    }

    func showCustomDomains() {
        let coordinator = DomainSettingsCoordinator(source: .dashboardOnboarding,
                                                    site: site,
                                                    navigationController: navigationController,
                                                    onDomainPurchased: { [weak self] in
            self?.onTaskCompleted(.customizeDomains)
        })
        self.domainSettingsCoordinator = coordinator
        Task { @MainActor in
            coordinator.start()
        }
    }

    func launchStore(task: StoreOnboardingTask) {
        let coordinator = StoreOnboardingLaunchStoreCoordinator(site: site,
                                                                isLaunched: task.isComplete,
                                                                navigationController: navigationController,
                                                                onLearnMoreTapped: { [weak self] in
            self?.showPlanView()
        },
                                                                onStoreLaunched: { [weak self] in
            self?.onTaskCompleted(.launchStore)
        })
        self.launchStoreCoordinator = coordinator
        coordinator.start()
    }

    func showWCPaySetup() {
        let coordinator = StoreOnboardingPaymentsSetupCoordinator(task: .wcPay,
                                                                  site: site,
                                                                  navigationController: navigationController,
                                                                  onDismiss: { [weak self] in
             self?.reloadTasks()
         })
        self.paymentsSetupCoordinator = coordinator
        coordinator.start()
    }

    func showPaymentsSetup() {
        let coordinator = StoreOnboardingPaymentsSetupCoordinator(task: .payments,
                                                                  site: site,
                                                                  navigationController: navigationController,
                                                                  onDismiss: { [weak self] in
            self?.reloadTasks()
         })
        self.paymentsSetupCoordinator = coordinator
        coordinator.start()
    }

    func showStoreNameSetup() {
        let viewModel = StoreNameSetupViewModel(siteID: site.siteID, name: site.name, onNameSaved: { [weak self] in
            self?.onTaskCompleted(.storeName)
            self?.navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
                self?.showStoreNameNotice()
            }
        })
        let controller = StoreNameSetupHostingController(viewModel: viewModel)
        navigationController.present(controller, animated: true)
    }

    func showStoreNameNotice() {
        let notice = Notice(title: Localization.StoreNameNotice.title,
                            subtitle: Localization.StoreNameNotice.subtitle)
        noticePresenter.enqueue(notice: notice)
    }
}

private extension StoreOnboardingCoordinator {
    /// Navigates the user to the plan subscription details view.
    ///
    func showPlanView() {
        let subscriptionController = SubscriptionsHostingController(siteID: site.siteID)
        navigationController.show(subscriptionController, sender: self)
    }
}

private extension StoreOnboardingCoordinator {
    enum Localization {
        enum StoreNameNotice {
            static let title = NSLocalizedString(
                "Store Name Set!",
                comment: "Title on the notice presented when the store name is updated"
            )
            static let subtitle = NSLocalizedString(
                "To change again, visit Store Settings.",
                comment: "Subtitle on the notice presented when the store name is updated"
            )
        }
    }
}
