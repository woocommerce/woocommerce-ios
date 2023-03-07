import Foundation
import Yosemite
import MessageUI
import enum Hardware.CardReaderServiceError
import enum Hardware.UnderlyingError

final class BluetoothCardReaderPaymentAlertsProvider: CardReaderTransactionAlertsProviding {
    var name: String = ""
    var amount: String = ""
    var transactionType: CardPresentTransactionType

    init(transactionType: CardPresentTransactionType) {
        self.transactionType = transactionType
    }

    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalPreparingReader(cancelAction: onCancel)
    }

    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: Yosemite.CardReaderInput,
                         onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        name = title
        self.amount = amount
        return CardPresentModalTapCard(name: title,
                                       amount: amount,
                                       transactionType: transactionType,
                                       inputMethods: inputMethods,
                                       onCancel: onCancel)
    }

    func displayReaderMessage(message: String) -> CardPresentPaymentsModalViewModel {
        CardPresentModalDisplayMessage(name: name,
                                       amount: amount,
                                       message: message)
    }

    func processingTransaction(title: String) -> CardPresentPaymentsModalViewModel {
        name = title
        return CardPresentModalProcessing(name: name, amount: amount, transactionType: transactionType)
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
                    .refundCreation(let underlyingError),
                    .refundPayment(let underlyingError, _),
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

    func nonRetryableError(error: Error, dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalNonRetryableError(amount: amount, error: error, onDismiss: dismissCompletion)
    }

    func retryableError(tryAgain: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalRetryableError(primaryAction: tryAgain)
    }

    func cancelledOnReader() -> CardPresentPaymentsModalViewModel? {
        CardPresentModalNonRetryableError(amount: amount,
                                          error: CardReaderServiceError.paymentMethodCollection(underlyingError: .commandCancelled(from: .reader)),
                                          onDismiss: { })
    }
}

private extension BluetoothCardReaderPaymentAlertsProvider {
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
