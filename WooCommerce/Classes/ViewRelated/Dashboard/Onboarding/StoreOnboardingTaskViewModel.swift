import UIKit
import struct Yosemite.StoreOnboardingTask

struct StoreOnboardingTaskViewModel: Identifiable, Equatable {
    let id = UUID()
    let task: StoreOnboardingTask
    let icon: UIImage
    let title: String
    let subtitle: String
    let badgeText: String?

    var isComplete: Bool {
        task.isComplete
    }

    init(task: StoreOnboardingTask, isEligibleForProductDescriptionAI: Bool) {
        self.task = task
        switch task.type {
        case .storeDetails:
            icon = .storeDetailsImage
            title = Localization.StoreDetails.title
            subtitle = Localization.StoreDetails.subtitle
            badgeText = nil
        case .addFirstProduct:
            icon = .addProductImage
            title = Localization.AddFirstProduct.title
            subtitle = Localization.AddFirstProduct.subtitle
            badgeText = isEligibleForProductDescriptionAI ?
            Localization.AddFirstProduct.badgeText: nil
        case .launchStore:
            icon = .launchStoreImage
            title = Localization.LaunchStore.title
            subtitle = Localization.LaunchStore.subtitle
            badgeText = nil
        case .customizeDomains:
            icon = .customizeDomainsImage
            title = Localization.CustomizeDomains.title
            subtitle = Localization.CustomizeDomains.subtitle
            badgeText = nil
        case .payments, .woocommercePayments:
            icon = .getPaidImage
            title = Localization.Payments.title
            subtitle = Localization.Payments.subtitle
            badgeText = nil
        case .unsupported:
            icon = .checkCircleImage
            title = ""
            subtitle = ""
            badgeText = nil
        }
    }
}


extension StoreOnboardingTaskViewModel {
    enum Localization {
        enum StoreDetails {
            static let title = NSLocalizedString(
                "Tell us more about your store",
                comment: "Title of the Store details task to add details about the store."
            )
            static let subtitle = NSLocalizedString(
                "We’ll use the info to get a head start on your shipping, tax, and payments settings.",
                comment: "Subtitle of the Store details task to add details about the store."
            )
        }

        enum AddFirstProduct {
            static let title = NSLocalizedString(
                "Add your first product",
                comment: "Title of the store onboarding task to add the first product."
            )
            static let subtitle = NSLocalizedString(
                "Start selling by adding products or services to your store.",
                comment: "Subtitle of the store onboarding task to add the first product."
            )
            static let badgeText = NSLocalizedString(
                "✨ AI content generator available.",
                comment: "Badge of the store onboarding task to add the first product when the store is eligible for Jetpack AI."
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
