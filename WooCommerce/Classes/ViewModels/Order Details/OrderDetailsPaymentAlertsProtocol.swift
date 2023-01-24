import UIKit
import Yosemite

/// Protocol for `OrderDetailsPaymentAlerts` to enable unit testing.
protocol OrderDetailsPaymentAlertsProtocol {
    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel)

    func preparingReader(onCancel: @escaping () -> Void)

    func tapOrInsertCard(title: String, amount: String, inputMethods: CardReaderInput, onCancel: @escaping () -> Void)

    func displayReaderMessage(message: String)

    func processingPayment(title: String)

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void, noReceiptAction: @escaping () -> Void)

    func error(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void)

    func nonRetryableError(from: UIViewController?, error: Error, dismissCompletion: @escaping () -> Void)

    func retryableError(from: UIViewController?, tryAgain: @escaping () -> Void)
}
