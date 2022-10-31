import Foundation
import UIKit

struct ProductsOnboardingAnnouncementCardViewModel: AnnouncementCardViewModelProtocol {
    var showDividers: Bool = false

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
        ServiceLocator.analytics.track(.productsOnboardingCTATapped)
        onCTATapped?()
    }

    // MARK: Dismiss button (disabled)

    var showDismissButton: Bool = false

    func dontShowAgainTapped() {
        // No-op
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
        static let buttonTitle = NSLocalizedString("Add a Product", comment: "Title for the button on the Products onboarding banner")
    }
}
