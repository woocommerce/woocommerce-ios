import Foundation
import Yosemite
import MessageUI
import enum Hardware.CardReaderServiceError
import enum Hardware.UnderlyingError

final class BuiltInCardReaderPaymentAlertsProvider: CardReaderTransactionAlertsProviding {
    var name: String = ""
    var amount: String = ""

    func validatingOrder(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalPreparingForPayment(bottomTitle: Localization.validatingOrderBottomTitle,
                                        cancelAction: onCancel)
    }

    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        CardPresentModalPreparingForPayment(bottomTitle: Localization.preparingReaderBottomTitle,
                                        cancelAction: onCancel)
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
                                              inputMethods: inputMethods)
    }

    func displayReaderMessage(message: String) -> CardPresentPaymentsModalViewModel {
        CardPresentModalDisplayMessage(name: name,
                                       amount: amount,
                                       message: message)
    }

    func processingTransaction(title: String) -> CardPresentPaymentsModalViewModel {
        name = title
        return CardPresentModalBuiltInReaderProcessing(name: name, amount: amount)
    }

    func success(receiptState: CardReaderTransactionAlertReceiptState) -> CardPresentPaymentsModalViewModel {
        switch receiptState {
        case let .paymentSuccessEmailSent(email, printReceiptAction, noReceiptAction):
            return CardPresentModalBuiltInSuccessEmailSent(printReceipt: printReceiptAction,
                                                           noReceiptAction: noReceiptAction,
                                                           email: email)
        case let .promptToSendEmailReceipt(printReceiptAction, emailReceiptAction, noReceiptAction):
            return CardPresentModalBuiltInSuccess(printReceipt: printReceiptAction,
                                                  emailReceipt: emailReceiptAction,
                                                  noReceiptAction: noReceiptAction)
        case let .emailSendingNotSupported(printReceiptAction, noReceiptAction):
            return CardPresentModalBuiltInSuccessWithoutEmail(printReceipt: printReceiptAction, noReceiptAction: noReceiptAction)
        }
    }

    func error(error: Error,
               receiptState: CardReaderTransactionFailureAlertReceiptState,
               tryAgain: @escaping () -> Void,
               dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        switch receiptState {
        case let .paymentSuccessEmailSent(email):
            return CardPresentModalErrorEmailSent(errorDescription: builtInReaderDescription(for: error),
                                                  transactionType: .collectPayment,
                                                  image: .builtInReaderError,
                                                  email: email,
                                                  requiresFallbackPaymentMethod: errorRequiresFallbackPaymentMethod(error),
                                                  tryAgainAction: tryAgain,
                                                  dismissCompletion: dismissCompletion)
        case let .promptToSendEmailReceipt(emailReceiptAction):
            return CardPresentModalError(errorDescription: builtInReaderDescription(for: error),
                                         transactionType: .collectPayment,
                                         image: .builtInReaderError,
                                         requiresFallbackPaymentMethod: errorRequiresFallbackPaymentMethod(error),
                                         tryAgainAction: tryAgain,
                                         emailReceiptAction: emailReceiptAction,
                                         dismissCompletion: dismissCompletion)
        case .noEmailReceipt:
            return CardPresentModalErrorWithoutEmail(errorDescription: builtInReaderDescription(for: error),
                                                     transactionType: .collectPayment,
                                                     image: .builtInReaderError,
                                                     requiresFallbackPaymentMethod: errorRequiresFallbackPaymentMethod(error),
                                                     tryAgainAction: tryAgain,
                                                     dismissCompletion: dismissCompletion)
        }
    }

    func nonRetryableError(error: Error,
                           receiptState: CardReaderTransactionFailureAlertReceiptState,
                           dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel {
        switch receiptState {
        case let .paymentSuccessEmailSent(email):
            CardPresentModalNonRetryableErrorEmailSent(amount: amount,
                                                       errorDescription: builtInReaderDescription(for: error),
                                                       image: .builtInReaderError,
                                                       email: email,
                                                       requiresFallbackPaymentMethod: errorRequiresFallbackPaymentMethod(error),
                                                       onDismiss: dismissCompletion)
        case let .promptToSendEmailReceipt(emailReceiptAction):
            CardPresentModalNonRetryableError(amount: amount,
                                              errorDescription: builtInReaderDescription(for: error),
                                              image: .builtInReaderError,
                                              requiresFallbackPaymentMethod: errorRequiresFallbackPaymentMethod(error),
                                              onDismiss: dismissCompletion,
                                              emailReceiptAction: emailReceiptAction)
        case .noEmailReceipt:
            CardPresentModalNonRetryableErrorWithoutEmail(amount: amount,
                                                          errorDescription: builtInReaderDescription(for: error),
                                                          image: .builtInReaderError,
                                                          requiresFallbackPaymentMethod: errorRequiresFallbackPaymentMethod(error),
                                                          onDismiss: dismissCompletion)
        }
    }

    func cancelledOnReader() -> CardPresentPaymentsModalViewModel? {
        return nil
    }
}

private extension BuiltInCardReaderPaymentAlertsProvider {
    func builtInReaderDescription(for error: Error) -> String? {
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
                return Localization.errorDescription(underlyingError: underlyingError)
            default:
                return error.errorDescription
            }
        } else {
            return error.localizedDescription
        }
    }

    func errorRequiresFallbackPaymentMethod(_ error: Error) -> Bool {
        if let error = error as? CardPaymentErrorProtocol {
            return error.requiresFallbackPaymentMethod
        } else {
            return false
        }
    }

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
            case .notConnectedToReader:
                return NSLocalizedString(
                    "The payment was interrupted and cannot be continued. You can retry the payment from the order screen.",
                    comment: "Error shown when the built-in card reader payment is interrupted by activity on the phone")
            default:
                return underlyingError.errorDescription
            }
        }

        static let preparingReaderBottomTitle = NSLocalizedString(
            "Preparing Tap to Pay on iPhone ",
            comment: "Bottom title of the alert presented with a spinner while Tap to Pay on iPhone is being prepared"
        )

        static let validatingOrderBottomTitle = NSLocalizedString(
            "Checking order",
            comment: "Bottom title of the alert presented with a spinner while the order is being validated"
        )
    }
}
