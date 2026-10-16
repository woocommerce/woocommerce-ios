import Foundation
import PointOfSale
import struct Yosemite.CardReaderInput

struct CardPresentPaymentsTransactionAlertsProvider: CardReaderTransactionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentEventDetails

    private let showsTapToPayCancellationConfirmation: Bool

    init(showsTapToPayCancellationConfirmation: Bool = false) {
        self.showsTapToPayCancellationConfirmation = showsTapToPayCancellationConfirmation
    }

    func validatingOrder(onCancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .validatingOrder(cancelPayment: onCancel)
    }

    func preparingReader(onCancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .preparingForPayment(cancelPayment: onCancel)
    }

    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: CardReaderInput,
                         onCancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .tapSwipeOrInsertCard(inputMethods: inputMethods,
                              cancelPayment: onCancel)
    }

    func cardInserted(title: String,
                      amount: String,
                      onCancel: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .cardInserted(cancelPayment: onCancel)
    }

    func displayReaderMessage(message: String) -> CardPresentPaymentEventDetails {
        .displayReaderMessage(message: message)
    }

    func processingTransaction(title: String) -> CardPresentPaymentEventDetails {
        .processing
    }

    func success(receiptState: CardReaderTransactionAlertReceiptState) -> CardPresentPaymentEventDetails {
        .paymentSuccess(done: receiptState.noReceiptAction)
    }

    func error(error: any Error,
               receiptState: CardReaderTransactionFailureAlertReceiptState,
               tryAgain: @escaping @MainActor @Sendable () -> Void,
               dismissCompletion: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .paymentError(error: error,
                      retryApproach: CardPresentPaymentRetryApproach(error: error, retryAction: tryAgain),
                      cancelPayment: dismissCompletion)
    }

    func nonRetryableError(error: any Error,
                           receiptState: CardReaderTransactionFailureAlertReceiptState,
                           dismissCompletion: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails {
        .paymentError(error: error,
                      retryApproach: .dontRetry,
                      cancelPayment: dismissCompletion)
    }

    func cancelledOnReader() -> CardPresentPaymentEventDetails? {
        .cancelledOnReader
    }

    func paymentCancellationConfirmation(onDismiss: @escaping @MainActor @Sendable () -> Void) -> CardPresentPaymentEventDetails? {
        guard showsTapToPayCancellationConfirmation else { return nil }
        return .paymentCancellationConfirmation(onDismiss: onDismiss)
    }
}
