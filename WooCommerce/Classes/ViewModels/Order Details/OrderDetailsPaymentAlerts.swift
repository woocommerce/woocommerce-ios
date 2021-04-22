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
        let newConfiguraton = FancyAlertViewController.configuration(title: "Tap, insert or swipe to pay", bodyText: amount ?? "", image: .cardPresentImage)
        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func removeCard() {
        let newConfiguraton = FancyAlertViewController.configuration(title: "Please remove card", bodyText: "", image: .cardPresentImage)
        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void) {
        let newConfiguraton = FancyAlertViewController
            .configurationForSuccess(title: "Payment successful",
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
