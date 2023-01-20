import Foundation
import UIKit
import enum Yosemite.AppSettingsAction

struct ProductsOnboardingAnnouncementCardViewModel: AnnouncementCardViewModelProtocol {
    var showDividers: Bool = true

    var badgeType: BadgeView.BadgeType = .tip

    var title: String = Localization.title

    var message: String = Localization.message

    var buttonTitle: String? = Localization.buttonTitle

    var image: UIImage = .emptyProductsImage

    func onAppear() {
        // No-op
    }

    // MARK: Call to Action

    let onCTATapped: (() -> Void)?

    func ctaTapped() {
        ServiceLocator.analytics.track(event: .ProductsOnboarding.bannerCTATapped())
        onCTATapped?()
    }

    // MARK: Dismiss button

    /// Ensures the banner isn't shown again after the user manually dismisses it.
    ///
    func dontShowAgainTapped() {
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: .productsOnboarding,
                                                                       remindAfterDays: nil,
                                                                       onCompletion: nil)
        ServiceLocator.stores.dispatch(action)
    }

    // MARK: Dismiss confirmation alert (disabled)

    var showDismissConfirmation: Bool = false

    var dismissAlertTitle: String = ""

    var dismissAlertMessage: String = ""

    func remindLaterTapped() {
        // No-op
    }
}

private extension ProductsOnboardingAnnouncementCardViewModel {
    enum Localization {
        static let title = NSLocalizedString("Add products to sell", comment: "Title for the Products onboarding banner")
        static let message = NSLocalizedString("Build your catalog by adding what you want to sell.", comment: "Message for the Products onboarding banner")
        static let buttonTitle = NSLocalizedString("Add a product", comment: "Title for the button on the Products onboarding banner")
    }
}
