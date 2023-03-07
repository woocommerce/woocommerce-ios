import UIKit
import Yosemite

/// Defines a protocol for card reader transaction alert providers to conform to - defining what
/// alert viewModels such a provider is expected to provide over the course of performind
/// a card present transaction (payment or refund.)
///
protocol CardReaderTransactionAlertsProviding {
    /// A cancellable alert indicating we are preparing a reader to collect card details
    ///
    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// A cancellable alert indicating the reader is ready to collect card details
    ///
    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: CardReaderInput,
                         onCancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// An alert to display a message from a reader
    ///
    func displayReaderMessage(message: String) -> CardPresentPaymentsModalViewModel

    /// An alert to show that the transaction is being processed
    ///
    func processingTransaction(title: String) -> CardPresentPaymentsModalViewModel

    /// An alert to display successful transaction and provide options related to receipts
    ///
    func success(printReceipt: @escaping () -> Void,
                 emailReceipt: @escaping () -> Void,
                 noReceiptAction: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// An alert to display a retriable and cancellable error
    ///
    func error(error: Error,
               tryAgain: @escaping () -> Void,
               dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// An alert to display a non-retriable and cancellable error
    ///
    func nonRetryableError(error: Error,
                           dismissCompletion: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// An alert to display a retriable error
    ///
    func retryableError(tryAgain: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// An alert to notify the merchant that the transaction was cancelled using a button on the reader
    ///
    func cancelledOnReader() -> CardPresentPaymentsModalViewModel?
}
