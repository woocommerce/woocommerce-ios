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
    private var wooPaySetupCelebrationViewBottomSheetPresenter: BottomSheetPresenter?

    let site: Site
    private let onTaskCompleted: (_ task: TaskType) -> Void
    private let reloadTasks: () -> Void

    init(navigationController: UINavigationController,
         site: Site,
         onTaskCompleted: @escaping (_ task: TaskType) -> Void,
         reloadTasks: @escaping () -> Void) {
        self.navigationController = navigationController
        self.site = site
        self.onTaskCompleted = onTaskCompleted
        self.reloadTasks = reloadTasks
    }

    /// Navigates to the fullscreen store onboarding view.
    func start() {
        Task { @MainActor in
            let onboardingNavigationController = UINavigationController()
            let onboardingViewController = StoreOnboardingViewHostingController(viewModel: .init(siteID: site.siteID,
                                                                                                 isExpanded: true),
                                                                                navigationController: onboardingNavigationController,
                                                                                site: site)
            onboardingNavigationController.pushViewController(onboardingViewController, animated: false)
            navigationController.present(onboardingNavigationController, animated: true)
        }
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
                                                                  onCompleted: { [weak self] in
            self?.onTaskCompleted(.woocommercePayments)
            self?.showWooPaySetupCelebrationView()
        },
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

    func showWooPaySetupCelebrationView() {
        wooPaySetupCelebrationViewBottomSheetPresenter = buildBottomSheetPresenter()
        let controller = CelebrationHostingController(
            title: Localization.Celebration.title,
            subtitle: Localization.Celebration.subtitle,
            closeButtonTitle: Localization.Celebration.done,
            onTappingDone: { [weak self] in
            self?.wooPaySetupCelebrationViewBottomSheetPresenter?.dismiss()
            self?.wooPaySetupCelebrationViewBottomSheetPresenter = nil
        })
        wooPaySetupCelebrationViewBottomSheetPresenter?.present(controller, from: navigationController)
    }
}

// MARK: Bottom sheet helpers
//
private extension StoreOnboardingCoordinator {
    func buildBottomSheetPresenter() -> BottomSheetPresenter {
        BottomSheetPresenter(configure: { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .none
            sheet.prefersGrabberVisible = true
            sheet.detents = [.medium()]
        })
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
        enum Celebration {
            static let title = NSLocalizedString(
                "You did it!",
                comment: "Title in Woo Payments setup celebration screen."
            )

            static let subtitle = NSLocalizedString(
                "Congratulations! You've successfully navigated through the setup and your payment system is ready to roll.",
                comment: "Subtitle in Woo Payments setup celebration screen."
            )
            static let done = NSLocalizedString(
                "Done",
                comment: "Dismiss button title in Woo Payments setup celebration screen."
            )
        }
    }
}
