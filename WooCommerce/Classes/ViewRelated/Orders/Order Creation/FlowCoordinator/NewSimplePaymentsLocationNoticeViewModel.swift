import SwiftUI

final class NewSimplePaymentsLocationNoticeViewModel {
    let title: String
    let message: String
    let confirmationButtonMessage: String
    let icon: UIImage = .walletImage

    /// Redirects to `HubMenu`tabBar
    ///
    var navigateToMenuButtonWasTapped: () -> Void = {
        guard let mainTabBarController = AppDelegate.shared.tabBarController else {
            return
        }
        mainTabBarController.navigateTo(.hubMenu)
    }

    init() {
        title = Localization.title
        message = Localization.message
        confirmationButtonMessage = Localization.confirmationButtonMessage
    }

}

extension NewSimplePaymentsLocationNoticeViewModel {
    enum Localization {
        static let title = NSLocalizedString("Payments from the Menu tab",
                                             comment: "Title of the bottom announcement modal when a merchant taps on Simple Payment")
        static let message = NSLocalizedString("Now you can quickly access In-Person Payments and other features with ease.",
                                               comment: "Message of the bottom announcement modal when a merchant taps on Simple Payment")
        static let confirmationButtonMessage = NSLocalizedString("Got it!",
                                                          comment: "Confirmation text of the button on the bottom announcement modal" +
                                                          "when a merchant taps on Simple Payment")
    }
}
