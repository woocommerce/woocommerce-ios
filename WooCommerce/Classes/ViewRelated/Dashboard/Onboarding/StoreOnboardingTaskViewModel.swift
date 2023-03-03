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
            title = Localication.AddFirstProduct.title
            subtitle = Localication.AddFirstProduct.subtitle
        case .launchStore:
            icon = .launchStoreImage
            title = Localication.LaunchStore.title
            subtitle = Localication.LaunchStore.subtitle
        case .customizeDomains:
            icon = .domainsImage
            title = Localication.CustomizeDomains.title
            subtitle = Localication.CustomizeDomains.subtitle
        case .payments:
            icon = .currencyImage
            title = Localication.Payments.title
            subtitle = Localication.Payments.subtitle
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


extension StoreOnboardingTaskViewModel {
    enum Localication {
        enum AddFirstProduct {
            static let title = NSLocalizedString(
                "Add your first product",
                comment: "Title of the store onboarding task to add the first product."
            )
            static let subtitle = NSLocalizedString(
                "Start selling by adding products or services to your store.",
                comment: "Subtitle of the store onboarding task to add the first product."
            )
        }

        enum LaunchStore {
            static let title = NSLocalizedString(
                "Launch your store",
                comment: "Title of the store onboarding task to launch the store."
            )
            static let subtitle = NSLocalizedString(
                "Publish your site to the world anytime you want!",
                comment: "Subtitle of the store onboarding task to launch the store."
            )
        }

        enum CustomizeDomains {
            static let title = NSLocalizedString(
                "Customize your domain",
                comment: "Title of the store onboarding task to customize the store domain."
            )
            static let subtitle = NSLocalizedString(
                "Have a custom URL to host your store.",
                comment: "Subtitle of the store onboarding task to customize the store domain."
            )
        }

        enum Payments {
            static let title = NSLocalizedString(
                "Get paid",
                comment: "Title of the store onboarding task to get paid."
            )
            static let subtitle = NSLocalizedString(
                "Give your customers an easy and convenient way to pay!",
                comment: "Subtitle of the store onboarding task to get paid."
            )
        }
    }
}
