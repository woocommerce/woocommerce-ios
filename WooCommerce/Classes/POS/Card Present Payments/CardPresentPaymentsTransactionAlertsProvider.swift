import Foundation
import struct Yosemite.CardReaderInput

struct CardPresentPaymentsTransactionAlertsProvider: CardReaderTransactionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentAlertDetails

    func validatingOrder(onCancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .validatingOrder(onCancel: onCancel)
    }

    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .preparingForPayment(onCancel: onCancel)
    }

    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: CardReaderInput,
                         onCancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .tapSwipeOrInsertCard(inputMethods: inputMethods,
                              cancel: onCancel)
    }

    func displayReaderMessage(message: String) -> CardPresentPaymentAlertDetails {
        .displayReaderMessage(message: message)
    }

    func processingTransaction(title: String) -> CardPresentPaymentAlertDetails {
        .processing
    }

    func success(printReceipt: @escaping () -> Void,
                 emailReceipt: @escaping () -> Void,
                 noReceiptAction: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .success(done: noReceiptAction)
    }

    func error(error: any Error,
               tryAgain: @escaping () -> Void,
               dismissCompletion: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .error(error: error,
               tryAgain: tryAgain,
               dismissCompletion: dismissCompletion)
    }

    func nonRetryableError(error: any Error,
                           dismissCompletion: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .errorNonRetryable(error: error,
                           dismissCompletion: dismissCompletion)
    }

    func cancelledOnReader() -> CardPresentPaymentAlertDetails? {
        .cancelledOnReader
    }
}
