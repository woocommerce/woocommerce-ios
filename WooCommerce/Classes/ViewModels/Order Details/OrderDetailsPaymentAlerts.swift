import UIKit
import WordPressUI

/// A layer of indirection between OrderDetailsViewController and the modal alerts
/// presented to provide user-facing feedback about the progress
/// of the payment collection process
/// It is using a FancyAlertViewController at the moment, but this is the class
/// to rewrite whenever we have the UI finalized.
/// https://github.com/woocommerce/woocommerce-ios/issues/3980
final class OrderDetailsPaymentAlerts {
    //private var alertController: FancyAlertViewController?
    private var modalController: UIViewController?
    //private var name: String
    //private var amount: String

    func readerIsReady(from: UIViewController, title: String, amount: String) {
        //self.name = title
        //self.amount = amount

        // Initial presentation of the modal view controller. We need to provide
        // a customer name and an amount.
        let viewModel = readerIsReady(name: title, amount: amount)
        let newAlert = CardPresentPaymentsModalViewController(viewModel: viewModel)
        modalController = newAlert
        modalController?.modalPresentationStyle = .custom
        modalController?.transitioningDelegate = AppDelegate.shared.tabBarController
        from.present(newAlert, animated: true)
//        let newAlert = FancyAlertViewController.makeCollectPaymentAlert(name: title, amount: amount, image: .cardPresentImage)
//        alertController = newAlert
//        alertController?.modalPresentationStyle = .custom
//        alertController?.transitioningDelegate = AppDelegate.shared.tabBarController
//        from.present(newAlert, animated: true)
    }

    func tapOrInsertCard() {
//        let newConfiguraton = FancyAlertViewController.configurationForTappingCard(amount: amount ?? "")
//        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func removeCard() {
//        let newConfiguraton = FancyAlertViewController.configurationForRemovingCard()
//        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void) {
//        let newConfiguraton = FancyAlertViewController
//            .configurationForSuccess(printAction: printReceipt,
//                                     emailAction: emailReceipt)
//        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func error(error: Error, tryAgainAction: @escaping () -> Void) {
//        let newConfiguraton = FancyAlertViewController
//            .configurationForError(tryAgainAction: tryAgainAction)
//        alertController?.setViewConfiguration(newConfiguraton, animated: false)
    }

    func dismiss() {
        modalController?.dismiss(animated: true, completion: nil)
    }
}


private extension OrderDetailsPaymentAlerts {
    func readerIsReady(name: String, amount: String) -> CardPresentPaymentsModalViewModel {
        CardPresentModalReaderIsReady(name: name, amount: amount)
    }
}
