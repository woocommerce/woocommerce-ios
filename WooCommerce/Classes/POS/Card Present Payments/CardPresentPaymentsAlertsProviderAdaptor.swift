import Foundation
import struct Yosemite.CardReaderInput

final class CardPresentPaymentsAlertsProviderAdaptor: CardReaderTransactionAlertsProviding {
    private let adaptedProvider: BluetoothCardReaderPaymentAlertsProvider

    init() {
        self.adaptedProvider = BluetoothCardReaderPaymentAlertsProvider(transactionType: .collectPayment)
    }

    func validatingOrder(onCancel: @escaping () -> Void) -> any CardPresentPaymentsModalViewModel {
        adaptedProvider.validatingOrder(onCancel: onCancel)
    }

    func preparingReader(onCancel: @escaping () -> Void) -> any CardPresentPaymentsModalViewModel {
        adaptedProvider.preparingReader(onCancel: onCancel)
    }

    func tapOrInsertCard(title: String, amount: String, inputMethods: Yosemite.CardReaderInput, onCancel: @escaping () -> Void) -> any CardPresentPaymentsModalViewModel {
        adaptedProvider.tapOrInsertCard(title: title, amount: amount, inputMethods: inputMethods, onCancel: onCancel)
    }

    func displayReaderMessage(message: String) -> any CardPresentPaymentsModalViewModel {
        adaptedProvider.displayReaderMessage(message: message)
    }

    func processingTransaction(title: String) -> any CardPresentPaymentsModalViewModel {
        adaptedProvider.processingTransaction(title: title)
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void, noReceiptAction: @escaping () -> Void) -> any CardPresentPaymentsModalViewModel {
        adaptedProvider.success(printReceipt: printReceipt, emailReceipt: emailReceipt, noReceiptAction: noReceiptAction)
    }

    func error(error: any Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void) -> any CardPresentPaymentsModalViewModel {
        adaptedProvider.error(error: error, tryAgain: tryAgain, dismissCompletion: dismissCompletion)
    }

    func nonRetryableError(error: any Error, dismissCompletion: @escaping () -> Void) -> any CardPresentPaymentsModalViewModel {
        adaptedProvider.nonRetryableError(error: error, dismissCompletion: dismissCompletion)
    }

    func cancelledOnReader() -> (any CardPresentPaymentsModalViewModel)? {
        adaptedProvider.cancelledOnReader()
    }
}
