import UIKit
import WordPressUI

final class OrderDetailsPaymentAlerts {
    private var alertController: FancyAlertViewController?

    func presentInitialAlert(from: UIViewController) {
        let newAlert = FancyAlertViewController.makeCollectPaymentAlert()
        alertController = newAlert
        alertController?.modalPresentationStyle = .custom
        alertController?.transitioningDelegate = AppDelegate.shared.tabBarController
        from.present(newAlert, animated: true)
    }

    func dismiss() {
        alertController?.dismiss(animated: true, completion: nil)
    }
}
