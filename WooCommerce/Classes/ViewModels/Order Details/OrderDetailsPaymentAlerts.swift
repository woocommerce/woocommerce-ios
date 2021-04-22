import UIKit
import WordPressUI

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

    func success(printReceipt: @escaping () -> Void) {
        let newConfiguraton = FancyAlertViewController
            .configurationForSuccess(title: "Payment successful",
                                     bodyText: "",
                                     image: .paymentCelebrationImage,
                                     printAction: printReceipt)
        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func error(error: Error) {

    }

    func dismiss() {
        alertController?.dismiss(animated: true, completion: nil)
    }
}
