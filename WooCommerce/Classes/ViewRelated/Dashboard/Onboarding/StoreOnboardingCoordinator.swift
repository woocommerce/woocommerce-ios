import Foundation
import SwiftUI
import UIKit
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// Coordinates navigation for store onboarding.
final class StoreOnboardingCoordinator: Coordinator {
    let navigationController: UINavigationController

    private var domainSettingsCoordinator: DomainSettingsCoordinator?

    private let site: Site

    init(navigationController: UINavigationController, site: Site) {
        self.navigationController = navigationController
        self.site = site
    }

    /// Navigates to the fullscreen store onboarding view.
    @MainActor
    func start() {
        let onboardingController = UINavigationController(rootViewController: StoreOnboardingViewHostingController(viewModel: .init(isExpanded: true,
                                                                                                                                    siteID: site.siteID),
                                                 taskTapped: { [weak self] task in self?.start(task: task) }))
        navigationController.present(onboardingController, animated: true)
    }

    /// Navigates to complete an onboarding task.
    /// - Parameter task: the task to complete.
    @MainActor
    func start(task: StoreOnboardingTask) {
        switch task.type {
        case .customizeDomains:
            showCustomDomains()
        default:
            #warning("TODO: handle navigation for each onboarding task")
            start()
        }
    }
}

private extension StoreOnboardingCoordinator {
    @MainActor
    func showCustomDomains() {
        let coordinator = DomainSettingsCoordinator(source: .dashboardOnboarding, site: site, navigationController: navigationController)
        self.domainSettingsCoordinator = coordinator
        coordinator.start()
    }
}
