import UIKit
import WordPressUI

/// A layer of indirection between OrderDetailsViewController and the modal alerts
/// presented to provide user-facing feedback about the progress
/// of the payment collection process
/// It is using a FancyAlertViewController at the moment, but this is the class
/// to rewrite whenever we have the UI finalized.
/// https://github.com/woocommerce/woocommerce-ios/issues/3980
final class OrderDetailsPaymentAlerts {
    private var alertController: FancyAlertViewController?
    private var name: String?
    private var amount: String?

    func readerIsReady(from: UIViewController, name: String, amount: String) {
        self.name = name
        self.amount = amount

        let newAlert = FancyAlertViewController.makeCollectPaymentAlert(name: name, amount: amount, image: .cardPresentImage)
        alertController = newAlert
        alertController?.modalPresentationStyle = .custom
        alertController?.transitioningDelegate = AppDelegate.shared.tabBarController
        from.present(newAlert, animated: true)
    }

    func tapOrInsertCard() {
        let newConfiguraton = FancyAlertViewController.configuration(title: Localization.tapInsertOrSwipe,
                                                                     bodyText: amount ?? "",
                                                                     image: .cardPresentImage)
        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func removeCard() {
        let newConfiguraton = FancyAlertViewController.configuration(title: Localization.removeCard, bodyText: "", image: .cardPresentImage)
        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void) {
        let newConfiguraton = FancyAlertViewController
            .configurationForSuccess(title: Localization.paymentSucessful,
                                     bodyText: "",
                                     image: .paymentCelebrationImage,
                                     printAction: printReceipt,
                                     emailAction: emailReceipt)
        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func error(error: Error, tryAgainAction: @escaping () -> Void) {
        let newConfiguraton = FancyAlertViewController
            .configurationForError(image: .paymentCelebrationImage,
                                     tryAgainAction: tryAgainAction)
        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func dismiss() {
        alertController?.dismiss(animated: true, completion: nil)
    }
}


private extension OrderDetailsPaymentAlerts {
    enum Localization {
        static let tapInsertOrSwipe = NSLocalizedString(
            "Tap, insert or swipe to pay",
            comment: "Label asking users to tap present cards. Presented to users when a payment is going to be collected"
        )

        static let removeCard = NSLocalizedString(
            "Please remove card",
            comment: "Label asking users to remove present cards. Presented to users when a payment is in the process of being collected"
        )

        static let paymentSucessful = NSLocalizedString(
            "Payment successful",
            comment: "Label informing users that the payment sucedded. Presented to users when a payment is collected"
        )
    }
}
