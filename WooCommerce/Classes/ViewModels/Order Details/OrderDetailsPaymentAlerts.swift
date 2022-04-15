import MessageUI
import UIKit
import WordPressUI
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
            let controller = CardPresentPaymentsModalViewController(viewModel: readerIsReady(onCancel: {}))
            _modalController = controller
            return controller
        }
    }

    private var name: String = ""
    private var amount: String = ""

    private let transactionType: CardPresentTransactionType

    init(transactionType: CardPresentTransactionType,
         presentingController: UIViewController) {
        self.transactionType = transactionType
        self.presentingController = presentingController
    }

    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel) {
        let controller = modalController
        controller.setViewModel(viewModel)
        if controller.presentingViewController == nil {
            controller.modalPresentationStyle = .custom
            controller.transitioningDelegate = AppDelegate.shared.tabBarController
            presentingController?.present(controller, animated: true)
        }
    }

    func readerIsReady(title: String, amount: String, onCancel: @escaping () -> Void) {
        self.name = title
        self.amount = amount

        // Initial presentation of the modal view controller. We need to provide
        // a customer name and an amount.
        let viewModel = readerIsReady(onCancel: onCancel)
        presentViewModel(viewModel: viewModel)
    }

    func tapOrInsertCard(onCancel: @escaping () -> Void) {
        let viewModel = tapOrInsert(onCancel: onCancel)
        presentViewModel(viewModel: viewModel)
    }

    func displayReaderMessage(message: String) {
        let viewModel = displayMessage(message: message)
        presentViewModel(viewModel: viewModel)
    }

    func processingPayment() {
        let viewModel = processing()
        presentViewModel(viewModel: viewModel)
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void, noReceiptTitle: String, noReceiptAction: @escaping () -> Void) {
        let viewModel = successViewModel(printReceipt: printReceipt,
                                         emailReceipt: emailReceipt,
                                         noReceiptTitle: noReceiptTitle,
                                         noReceiptAction: noReceiptAction)
        presentViewModel(viewModel: viewModel)
    }

    func error(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void) {
        let viewModel = errorViewModel(error: error, tryAgain: tryAgain, dismissCompletion: dismissCompletion)
        presentViewModel(viewModel: viewModel)
    }

    func nonRetryableError(from: UIViewController?, error: Error) {
        let viewModel = nonRetryableErrorViewModel(amount: amount, error: error)
        presentViewModel(viewModel: viewModel)
    }

    func retryableError(from: UIViewController?, tryAgain: @escaping () -> Void) {
        let viewModel = retryableErrorViewModel(tryAgain: tryAgain)
        presentViewModel(viewModel: viewModel)
    }
}

private extension OrderDetailsPaymentAlerts {
    func readerIsReady(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalReaderIsReady(name: name,
                                      amount: amount,
                                      transactionType: transactionType,
                                      cancelAction: onCancel)
    }

    func tapOrInsert(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalTapCard(name: name, amount: amount, transactionType: transactionType, onCancel: onCancel)
    }

    func displayMessage(message: String) -> CardPresentPaymentsModalViewModel {
        CardPresentModalDisplayMessage(name: name, amount: amount, message: message)
    }

    func processing() -> CardPresentPaymentsModalViewModel {
        CardPresentModalProcessing(name: name, amount: amount, transactionType: transactionType)
    }

    func successViewModel(printReceipt: @escaping () -> Void,
                          emailReceipt: @escaping () -> Void,
                          noReceiptTitle: String,
                          noReceiptAction: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if MFMailComposeViewController.canSendMail() {
            return CardPresentModalSuccess(printReceipt: printReceipt,
                                           emailReceipt: emailReceipt,
                                           noReceiptTitle: noReceiptTitle,
                                           noReceiptAction: noReceiptAction)
        } else {
            return CardPresentModalSuccessWithoutEmail(printReceipt: printReceipt, noReceiptTitle: noReceiptTitle, noReceiptAction: noReceiptAction)
        }
    }

    func errorViewModel(error: Error,
                        tryAgain: @escaping () -> Void,
                        dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        let errorDescription: String?
        if let error = error as? CardReaderServiceError {
            switch error {
            case .connection(let underlyingError),
                    .discovery(let underlyingError),
                    .disconnection(let underlyingError),
                    .intentCreation(let underlyingError),
                    .paymentMethodCollection(let underlyingError),
                    .paymentCapture(let underlyingError),
                    .paymentCancellation(let underlyingError),
                    .refundCreation(let underlyingError),
                    .refundPayment(let underlyingError),
                    .refundCancellation(let underlyingError),
                    .softwareUpdate(let underlyingError, _):
                errorDescription = Localization.errorDescription(underlyingError: underlyingError, transactionType: transactionType)
            default:
                errorDescription = error.errorDescription
            }
        } else {
            errorDescription = error.localizedDescription
        }
        return CardPresentModalError(errorDescription: errorDescription,
                                     transactionType: transactionType,
                                     primaryAction: tryAgain,
                                     dismissCompletion: dismissCompletion)
    }

    func retryableErrorViewModel(tryAgain: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalRetryableError(primaryAction: tryAgain)
    }

    func nonRetryableErrorViewModel(amount: String, error: Error) -> CardPresentPaymentsModalViewModel {
        CardPresentModalNonRetryableError(amount: amount, error: error)
    }
}

private extension OrderDetailsPaymentAlerts {
    enum Localization {
        static func errorDescription(underlyingError: UnderlyingError, transactionType: CardPresentTransactionType) -> String? {
            switch underlyingError {
            case .unsupportedReaderVersion:
                switch transactionType {
                case .collectPayment:
                    return NSLocalizedString(
                        "The card reader software is out-of-date - please update the card reader software before attempting to process payments",
                        comment: "Error message when the card reader software is too far out of date to process payments."
                    )
                case .refund:
                    return NSLocalizedString(
                        "The card reader software is out-of-date - please update the card reader software before attempting to process refunds",
                        comment: "Error message when the card reader software is too far out of date to process in-person refunds."
                    )
                }
            case .paymentDeclinedByCardReader:
                switch transactionType {
                case .collectPayment:
                    return NSLocalizedString("The card was declined by the card reader - please try another means of payment",
                                             comment: "Error message when the card reader itself declines the card.")
                case .refund:
                    return NSLocalizedString("The card was declined by the card reader - please try another means of refund",
                                             comment: "Error message when the card reader itself declines the card.")
                }
            case .processorAPIError:
                switch transactionType {
                case .collectPayment:
                    return NSLocalizedString(
                        "The payment can not be processed by the payment processor.",
                        comment: "Error message when the payment can not be processed (i.e. order amount is below the minimum amount allowed.)"
                    )
                case .refund:
                    return NSLocalizedString(
                        "The refund can not be processed by the payment processor.",
                        comment: "Error message when the in-person refund can not be processed (i.e. order amount is below the minimum amount allowed.)"
                    )
                }
            case .internalServiceError:
                switch transactionType {
                case .collectPayment:
                    return NSLocalizedString(
                        "Sorry, this payment couldn’t be processed",
                        comment: "Error message when the card reader service experiences an unexpected internal service error."
                    )
                case .refund:
                    return NSLocalizedString(
                        "Sorry, this refund couldn’t be processed",
                        comment: "Error message when the card reader service experiences an unexpected internal service error."
                    )
                }
            default:
                return underlyingError.errorDescription
            }
        }
    }
}
