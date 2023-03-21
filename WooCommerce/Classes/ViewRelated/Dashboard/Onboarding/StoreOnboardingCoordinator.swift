import Foundation
import SwiftUI
import UIKit
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// Coordinates navigation for store onboarding.
final class StoreOnboardingCoordinator: Coordinator {
    let navigationController: UINavigationController

    private var addProductCoordinator: AddProductCoordinator?
    private var domainSettingsCoordinator: DomainSettingsCoordinator?
    private var launchStoreCoordinator: StoreOnboardingLaunchStoreCoordinator?
    private var paymentsSetupCoordinator: StoreOnboardingPaymentsSetupCoordinator?

    private let site: Site
    private weak var presentationControllerDelegate: UIAdaptivePresentationControllerDelegate?

    init(navigationController: UINavigationController,
         site: Site,
         presentationControllerDelegate: UIAdaptivePresentationControllerDelegate? = nil) {
        self.navigationController = navigationController
        self.site = site
        self.presentationControllerDelegate = presentationControllerDelegate
    }

    /// Navigates to the fullscreen store onboarding view.
    @MainActor
    func start() {
        let onboardingNavigationController = UINavigationController()
        let onboardingViewController = StoreOnboardingViewHostingController(viewModel: .init(siteID: site.siteID,
                                                                                             isExpanded: true),
                                                                            navigationController: onboardingNavigationController,
                                                                            site: site)
        onboardingNavigationController.pushViewController(onboardingViewController, animated: false)
        onboardingNavigationController.presentationController?.delegate = presentationControllerDelegate
        navigationController.present(onboardingNavigationController, animated: true)
    }

    /// Navigates to complete an onboarding task.
    /// - Parameter task: the task to complete.
    @MainActor
    func start(task: StoreOnboardingTask) {
        switch task.type {
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
    @MainActor
    func addProduct() {
        let coordinator = AddProductCoordinator(siteID: site.siteID, sourceView: nil, sourceNavigationController: navigationController)
        self.addProductCoordinator = coordinator
        coordinator.onProductCreated = { _ in
            #warning("Analytics when a product is added from the onboarding task")
        }
        coordinator.start()
    }

    @MainActor
    func showCustomDomains() {
        let coordinator = DomainSettingsCoordinator(source: .dashboardOnboarding,
                                                    site: site,
                                                    navigationController: navigationController,
                                                    presentationControllerDelegate: presentationControllerDelegate)
        self.domainSettingsCoordinator = coordinator
        coordinator.start()
    }

    @MainActor
    func launchStore(task: StoreOnboardingTask) {
        let coordinator = StoreOnboardingLaunchStoreCoordinator(site: site,
                                                                isLaunched: task.isComplete,
                                                                navigationController: navigationController,
                                                                presentationControllerDelegate: presentationControllerDelegate)
        self.launchStoreCoordinator = coordinator
        coordinator.start()
    }

    @MainActor
    func showWCPaySetup() {
        let coordinator = StoreOnboardingPaymentsSetupCoordinator(task: .wcPay,
                                                                  site: site,
                                                                  navigationController: navigationController,
                                                                  presentationControllerDelegate: presentationControllerDelegate)
        self.paymentsSetupCoordinator = coordinator
        coordinator.start()
    }

    @MainActor
    func showPaymentsSetup() {
        let coordinator = StoreOnboardingPaymentsSetupCoordinator(task: .payments,
                                                                  site: site,
                                                                  navigationController: navigationController,
                                                                  presentationControllerDelegate: presentationControllerDelegate)
        self.paymentsSetupCoordinator = coordinator
        coordinator.start()
    }
}
