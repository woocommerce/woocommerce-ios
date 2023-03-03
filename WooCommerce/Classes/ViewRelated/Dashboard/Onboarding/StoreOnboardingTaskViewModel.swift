import UIKit
import struct Yosemite.StoreOnboardingTask

struct StoreOnboardingTaskViewModel: Identifiable, Equatable {
    let id = UUID()
    let task: StoreOnboardingTask
    let icon: UIImage
    let title: String
    let subtitle: String

    var isComplete: Bool {
        task.isComplete
    }

    init(task: StoreOnboardingTask) {
        self.task = task
        switch task.type {
        case .addFirstProduct:
            icon = .productImage
            title = NSLocalizedString(
                "Add your first product",
                comment: "Title of the store onboarding task to add the first product."
            )
            subtitle = NSLocalizedString(
                "Start selling by adding products or services to your store.",
                comment: "Subtitle of the store onboarding task to add the first product."
            )
        case .launchStore:
            icon = .launchStoreImage
            title = NSLocalizedString(
                "Launch your store",
                comment: "Title of the store onboarding task to launch the store."
            )
            subtitle = NSLocalizedString(
                "Publish your site to the world anytime you want!",
                comment: "Subtitle of the store onboarding task to launch the store."
            )
        case .customizeDomains:
            icon = .domainsImage
            title = NSLocalizedString(
                "Customize your domain",
                comment: "Title of the store onboarding task to customize the store domain."
            )
            subtitle = NSLocalizedString(
                "Have a custom URL to host your store.",
                comment: "Subtitle of the store onboarding task to customize the store domain."
            )
        case .payments:
            icon = .currencyImage
            title = NSLocalizedString(
                "Get paid",
                comment: "Title of the store onboarding task to get paid."
            )
            subtitle = NSLocalizedString(
                "Give your customers an easy and convenient way to pay!",
                comment: "Subtitle of the store onboarding task to get paid."
            )
        case .unsupported:
            icon = .checkCircleImage
            title = ""
            subtitle = ""
        }
    }

    static func placeHolder() -> Self {
        .init(task: .init(isComplete: true,
                          type: .launchStore))
    }
}
