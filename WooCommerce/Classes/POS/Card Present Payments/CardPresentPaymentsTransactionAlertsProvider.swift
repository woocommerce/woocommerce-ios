import Foundation
import struct Yosemite.CardReaderInput

struct CardPresentPaymentsTransactionAlertsProvider: CardReaderTransactionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentAlertDetails

    func validatingOrder(onCancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .validatingOrder
    }

    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .preparingForPayment
    }

    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: CardReaderInput,
                         onCancel: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .tapCard
    }

    func displayReaderMessage(message: String) -> CardPresentPaymentAlertDetails {
        .displayReaderMessage
    }

    func processingTransaction(title: String) -> CardPresentPaymentAlertDetails {
        .processing
    }

    func success(printReceipt: @escaping () -> Void,
                 emailReceipt: @escaping () -> Void,
                 noReceiptAction: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .success
    }

    func error(error: any Error,
               tryAgain: @escaping () -> Void,
               dismissCompletion: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .error
    }

    func nonRetryableError(error: any Error,
                           dismissCompletion: @escaping () -> Void) -> CardPresentPaymentAlertDetails {
        .errorNonRetryable
    }

    func cancelledOnReader() -> CardPresentPaymentAlertDetails? {
        .cancelledOnReader
    }
}
