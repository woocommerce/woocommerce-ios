import Foundation
import struct Yosemite.CardReaderInput

struct CardPresentPaymentsTransactionAlertsProvider: CardReaderTransactionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentEventDetails

    func validatingOrder(onCancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .validatingOrder(cancelPayment: onCancel)
    }

    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .preparingForPayment(cancelPayment: onCancel)
    }

    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: CardReaderInput,
                         onCancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .tapSwipeOrInsertCard(inputMethods: inputMethods,
                              cancelPayment: onCancel)
    }

    func displayReaderMessage(message: String) -> CardPresentPaymentEventDetails {
        .displayReaderMessage(message: message)
    }

    func processingTransaction(title: String) -> CardPresentPaymentEventDetails {
        .processing
    }

    func success(printReceipt: @escaping () -> Void,
                 emailReceipt: @escaping () -> Void,
                 noReceiptAction: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .paymentSuccess(done: noReceiptAction)
    }

    func error(error: any Error,
               tryAgain: @escaping () -> Void,
               dismissCompletion: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .paymentError(error: error,
                      retryApproach: CardPresentPaymentRetryApproach(error: error, retryAction: tryAgain),
                      cancelPayment: dismissCompletion)
    }

    func nonRetryableError(error: any Error,
                           dismissCompletion: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .paymentError(error: error,
                      retryApproach: .dontRetry,
                      cancelPayment: dismissCompletion)
    }

    func cancelledOnReader() -> CardPresentPaymentEventDetails? {
        .cancelledOnReader
    }
}
