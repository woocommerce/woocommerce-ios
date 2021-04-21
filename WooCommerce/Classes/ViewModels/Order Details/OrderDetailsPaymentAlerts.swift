import UIKit
import WordPressUI

final class OrderDetailsPaymentAlerts {
    private var alertController: FancyAlertViewController?

    func presentInitialAlert(from: UIViewController, name: String, amount: String) {
        let newAlert = FancyAlertViewController.makeCollectPaymentAlert(name: name, amount: amount)
        alertController = newAlert
        alertController?.modalPresentationStyle = .custom
        alertController?.transitioningDelegate = AppDelegate.shared.tabBarController
        from.present(newAlert, animated: true)
    }

    func updateAlertTitle(title: String) {
        let newConfiguraton = FancyAlertViewController.configuration(title: title, bodyText: "")
        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func dismiss() {
        alertController?.dismiss(animated: true, completion: nil)
    }
}
