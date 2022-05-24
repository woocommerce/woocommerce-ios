import UIKit

/// Protocol for `OrderDetailsPaymentAlerts` to enable unit testing.
protocol OrderDetailsPaymentAlertsProtocol {
    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel)

    func readerIsReady(title: String, amount: String, onCancel: @escaping () -> Void)

    func tapOrInsertCard(onCancel: @escaping () -> Void)

    func displayReaderMessage(message: String)

    func processingPayment()

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void, noReceiptAction: @escaping () -> Void)

    func error(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void)

    func serverSidePaymentCaptureError(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void)

    func nonRetryableError(from: UIViewController?, error: Error, dismissCompletion: @escaping () -> Void)

    func retryableError(from: UIViewController?, tryAgain: @escaping () -> Void)
}
