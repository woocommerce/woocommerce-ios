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

    func validatingOrder(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalPreparingForPayment(bottomTitle: Localization.validatingOrderBottomTitle,
                                        cancelAction: onCancel)
    }

    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalPreparingForPayment(cancelAction: onCancel)
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

    func success(receiptState: CardReaderTransactionAlertReceiptState) -> CardPresentPaymentsModalViewModel {
        switch receiptState {
        case let .paymentSuccessEmailSent(email, printReceiptAction, noReceiptAction):
            return CardPresentModalSuccessEmailSent(printReceipt: printReceiptAction,
                                                    noReceiptAction: noReceiptAction,
                                                    email: email)
        case let .promptToSendEmailReceipt(printReceiptAction, emailReceiptAction, noReceiptAction):
            return CardPresentModalSuccess(printReceipt: printReceiptAction,
                                           emailReceipt: emailReceiptAction,
                                           noReceiptAction: noReceiptAction)
        case let .emailSendingNotSupported(printReceiptAction, noReceiptAction):
            return CardPresentModalSuccessWithoutEmail(printReceipt: printReceiptAction, noReceiptAction: noReceiptAction)
        }
    }

    func error(error: Error,
               receiptState: CardReaderTransactionFailureAlertReceiptState,
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

        switch receiptState {
        case let .paymentSuccessEmailSent(email):
            return CardPresentModalErrorEmailSent(errorDescription: errorDescription,
                                                  transactionType: transactionType,
                                                  email: email,
                                                  tryAgainAction: tryAgain,
                                                  dismissCompletion: dismissCompletion)
        case let .promptToSendEmailReceipt(emailReceiptAction):
            return CardPresentModalError(errorDescription: errorDescription,
                                         transactionType: transactionType,
                                         tryAgainAction: tryAgain,
                                         emailReceiptAction: emailReceiptAction,
                                         dismissCompletion: dismissCompletion)
        case .noEmailReceipt:
            return CardPresentModalErrorWithoutEmail(errorDescription: errorDescription,
                                                     transactionType: transactionType,
                                                     tryAgainAction: tryAgain,
                                                     dismissCompletion: dismissCompletion)

        }
    }

    func nonRetryableError(error: Error,
                           receiptState: CardReaderTransactionFailureAlertReceiptState,
                           dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        switch receiptState {
        case let .paymentSuccessEmailSent(email):
            CardPresentModalNonRetryableErrorEmailSent(amount: amount, error: error, email: email, onDismiss: dismissCompletion)
        case let .promptToSendEmailReceipt(emailReceiptAction):
            CardPresentModalNonRetryableError(amount: amount,
                                              error: error,
                                              onDismiss: dismissCompletion,
                                              emailReceiptAction: emailReceiptAction)
        case .noEmailReceipt:
            CardPresentModalNonRetryableErrorWithoutEmail(amount: amount,
                                                          error: error,
                                                          onDismiss: dismissCompletion)
        }
    }

    func cancelledOnReader() -> CardPresentPaymentsModalViewModel? {
        CardPresentModalNonRetryableErrorWithoutEmail(amount: amount,
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

        static let validatingOrderBottomTitle = NSLocalizedString(
            "Checking order",
            comment: "Bottom title of the alert presented with a spinner while the order is being validated"
        )
    }
}
