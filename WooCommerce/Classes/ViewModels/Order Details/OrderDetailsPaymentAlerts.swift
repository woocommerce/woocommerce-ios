import MessageUI
import UIKit
import WordPressUI
import Yosemite
import enum Hardware.CardReaderServiceError
import enum Hardware.UnderlyingError

/// A layer of indirection between OrderDetailsViewController and the modal alerts
/// presented to provide user-facing feedback about the progress
/// of the payment collection process
final class OrderDetailsPaymentAlerts: OrderDetailsPaymentAlertsProtocol {
    private weak var presentingController: UIViewController?

    // Storing this as a weak variable means that iOS should automatically set this to nil
    // when the VC is dismissed, unless there is a retain cycle somewhere else.
    private weak var _modalController: CardPresentPaymentsModalViewController?
    private var modalController: CardPresentPaymentsModalViewController {
        if let controller = _modalController {
            return controller
        } else {
            let controller = CardPresentPaymentsModalViewController(
                viewModel: CardPresentModalPreparingReader(cancelAction: { [weak self] in
                    self?.presentingController?.dismiss(animated: true)
                }))
            _modalController = controller
            return controller
        }
    }

    private let transactionType: CardPresentTransactionType

    private let alertsProvider: CardReaderTransactionAlertsProviding

    init(transactionType: CardPresentTransactionType,
         presentingController: UIViewController) {
        self.transactionType = transactionType
        self.presentingController = presentingController
        self.alertsProvider = BluetoothCardReaderPaymentAlertsProvider(transactionType: transactionType)
    }

    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel) {
        let controller = modalController
        controller.setViewModel(viewModel)
        if controller.presentingViewController == nil {
            controller.prepareForCardReaderModalFlow()
            presentingController?.present(controller, animated: true)
        }
    }

    func preparingReader(onCancel: @escaping () -> Void) {
        presentViewModel(viewModel: CardPresentModalPreparingReader(cancelAction: onCancel))
    }

    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: CardReaderInput,
                         onCancel: @escaping () -> Void) {
        // Initial presentation of the modal view controller. We need to provide
        // a customer name and an amount.
        let viewModel = alertsProvider.tapOrInsertCard(title: title,
                                                       amount: amount,
                                                       inputMethods: inputMethods,
                                                       onCancel: onCancel)
        presentViewModel(viewModel: viewModel)
    }

    func displayReaderMessage(message: String) {
        let viewModel = alertsProvider.displayReaderMessage(message: message)
        presentViewModel(viewModel: viewModel)
    }

    func processingPayment(title: String) {
        let viewModel = alertsProvider.processingTransaction(title: title)
        presentViewModel(viewModel: viewModel)
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void, noReceiptAction: @escaping () -> Void) {
        let viewModel = alertsProvider.success(printReceipt: printReceipt,
                                               emailReceipt: emailReceipt,
                                               noReceiptAction: noReceiptAction)
        presentViewModel(viewModel: viewModel)
    }

    func error(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void) {
        let viewModel = alertsProvider.error(error: error,
                                             tryAgain: tryAgain,
                                             dismissCompletion: dismissCompletion)
        presentViewModel(viewModel: viewModel)
    }

    func nonRetryableError(from: UIViewController?, error: Error, dismissCompletion: @escaping () -> Void) {
        let viewModel = alertsProvider.nonRetryableError(error: error,
                                                         dismissCompletion: dismissCompletion)
        presentViewModel(viewModel: viewModel)
    }

    func retryableError(from: UIViewController?, tryAgain: @escaping () -> Void) {
        let viewModel = alertsProvider.retryableError(tryAgain: tryAgain)
        presentViewModel(viewModel: viewModel)
    }
}
