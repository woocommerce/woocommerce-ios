@testable import WooCommerce
import UIKit

/// Mock for `OrderDetailsPaymentAlertsProtocol`.
final class MockOrderDetailsPaymentAlerts: OrderDetailsPaymentAlertsProtocol {
    var cancelReaderIsReadyAlert: (() -> Void)?

    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel) {
        // no-op
    }

    func readerIsReady(title: String, amount: String, onCancel: @escaping () -> Void) {
        cancelReaderIsReadyAlert = onCancel
    }

    func tapOrInsertCard(onCancel: @escaping () -> Void) {
        // no-op
    }

    func displayReaderMessage(message: String) {
        // no-op
    }

    func processingPayment() {
        // no-op
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void, noReceiptTitle: String, noReceiptAction: @escaping () -> Void) {
        // no-op
    }

    func error(error: Error, tryAgain: @escaping () -> Void) {
        // no-op
    }

    func nonRetryableError(from: UIViewController?, error: Error) {
        // no-op
    }

    func retryableError(from: UIViewController?, tryAgain: @escaping () -> Void) {
        // no-op
    }
}
