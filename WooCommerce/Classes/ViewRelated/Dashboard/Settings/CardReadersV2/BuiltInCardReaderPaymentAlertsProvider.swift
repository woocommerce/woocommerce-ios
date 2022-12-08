import Foundation
import Yosemite
import MessageUI
import enum Hardware.CardReaderServiceError
import enum Hardware.UnderlyingError

final class BuiltInCardReaderPaymentAlertsProvider: CardReaderTransactionAlertsProviding {
    var name: String = ""
    var amount: String = ""

    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalPreparingReader(cancelAction: onCancel)
    }

    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: Yosemite.CardReaderInput,
                         onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        name = title
        self.amount = amount
        return CardPresentModalBuiltInFollowReaderInstructions(name: name,
                                              amount: amount,
                                              transactionType: .collectPayment,
                                              inputMethods: inputMethods,
                                              onCancel: { })
    }

    func displayReaderMessage(message: String) -> CardPresentPaymentsModalViewModel {
        CardPresentModalDisplayMessage(name: name,
                                       amount: amount,
                                       message: message)
    }

    func processingTransaction() -> CardPresentPaymentsModalViewModel {
        CardPresentModalBuiltInReaderProcessing(name: name, amount: amount)
    }

    func success(printReceipt: @escaping () -> Void,
                 emailReceipt: @escaping () -> Void,
                 noReceiptAction: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        if MFMailComposeViewController.canSendMail() {
            return CardPresentModalSuccess(printReceipt: printReceipt,
                                           emailReceipt: emailReceipt,
                                           noReceiptAction: noReceiptAction)
        } else {
            return CardPresentModalSuccessWithoutEmail(printReceipt: printReceipt, noReceiptAction: noReceiptAction)
        }
    }

    func error(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
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
                    .softwareUpdate(let underlyingError, _):
                errorDescription = Localization.errorDescription(underlyingError: underlyingError)
            default:
                errorDescription = error.errorDescription
            }
        } else {
            errorDescription = error.localizedDescription
        }
        return CardPresentModalError(errorDescription: errorDescription,
                                     transactionType: .collectPayment,
                                     primaryAction: tryAgain,
                                     dismissCompletion: dismissCompletion)
    }

    func nonRetryableError(error: Error, dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalNonRetryableError(amount: amount, error: error, onDismiss: dismissCompletion)
    }

    func retryableError(tryAgain: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalRetryableError(primaryAction: tryAgain)
    }
}

private extension BuiltInCardReaderPaymentAlertsProvider {
    enum Localization {
        static func errorDescription(underlyingError: UnderlyingError) -> String? {
            switch underlyingError {
            case .paymentDeclinedByCardReader:
                return NSLocalizedString("The card was declined by the iPhone card reader - please try another means of payment",
                                         comment: "Error message when the card reader itself declines the card.")
            case .processorAPIError:
                return NSLocalizedString(
                    "The payment can not be processed by the payment processor.",
                    comment: "Error message when the payment can not be processed (i.e. order amount is below the minimum amount allowed.)"
                )
            case .internalServiceError:
                return NSLocalizedString(
                    "Sorry, this payment couldn’t be processed",
                    comment: "Error message when the card reader service experiences an unexpected internal service error."
                )
            default:
                return underlyingError.errorDescription
            }
        }
    }
}
