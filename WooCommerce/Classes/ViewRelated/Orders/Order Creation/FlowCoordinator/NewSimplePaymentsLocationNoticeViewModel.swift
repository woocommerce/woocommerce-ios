import SwiftUI

final class NewSimplePaymentsLocationNoticeViewModel {
    let simplePaymentsNoticeView: DismissableNoticeView

    /// Redirects to `HubMenu`tabBar
    ///
    private var navigateToMenuButtonWasTapped: (() -> Void)? = {
        guard let mainTabBarController = AppDelegate.shared.tabBarController else {
            return
        }
        mainTabBarController.navigateTo(.hubMenu)
    }

    init() {
        simplePaymentsNoticeView = DismissableNoticeView(
            buttonTapped: navigateToMenuButtonWasTapped,
            title: Localization.title,
            message: Localization.message,
            confirmationButtonMessage: Localization.confirmationButton,
            icon: .walletImage
        )
    }
}

private extension NewSimplePaymentsLocationNoticeViewModel {
    enum Localization {
        static let title = NSLocalizedString("Payments from the Menu tab",
                                             comment: "Title of the bottom announcement modal when a merchant taps on Simple Payment")
        static let message = NSLocalizedString("Now you can quickly access In-Person Payments and other features with ease.",
                                               comment: "Message of the bottom announcement modal when a merchant taps on Simple Payment")
        static let confirmationButton = NSLocalizedString("Got it!",
                                                          comment: "Confirmation text of the button on the bottom announcement modal" +
                                                          "when a merchant taps on Simple Payment")
    }
}
