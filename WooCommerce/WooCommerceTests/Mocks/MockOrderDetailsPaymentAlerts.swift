@testable import WooCommerce
import UIKit

/// Mock for `OrderDetailsPaymentAlertsProtocol`.
final class MockOrderDetailsPaymentAlerts {
    // Public closures to mock alert actions and properties for assertions.
    var cancelReaderIsReadyAlert: (() -> Void)?

    var cancelTapOrInsertCardAlert: (() -> Void)?

    // Error alert.
    var error: Error?
    var retryFromError: (() -> Void)?
    var dismissErrorCompletion: (() -> Void)?
    var nonRetryableErrorWasCalled = false

    // Server-side payment capture error alert.
    var errorFromServerSidePaymentCapture: Error?
    var retryFromServerSidePaymentCaptureError: (() -> Void)?
    var dismissServerSidePaymentCaptureErrorCompletion: (() -> Void)?

    // Success alert.
    var printReceiptFromSuccessAlert: (() -> Void)?
    var emailReceiptFromSuccessAlert: (() -> Void)?
}

extension MockOrderDetailsPaymentAlerts: OrderDetailsPaymentAlertsProtocol {
    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel) {
        // no-op
    }

    func readerIsReady(title: String, amount: String, onCancel: @escaping () -> Void) {
        cancelReaderIsReadyAlert = onCancel
    }

    func tapOrInsertCard(onCancel: @escaping () -> Void) {
        cancelTapOrInsertCardAlert = onCancel
    }

    func displayReaderMessage(message: String) {
        // no-op
    }

    func processingPayment() {
        // no-op
    }

    func success(printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void, noReceiptAction: @escaping () -> Void) {
        printReceiptFromSuccessAlert = printReceipt
        emailReceiptFromSuccessAlert = emailReceipt
    }

    func error(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void) {
        self.error = error
        retryFromError = tryAgain
        dismissErrorCompletion = dismissCompletion
    }

    func serverSidePaymentCaptureError(error: Error, tryAgain: @escaping () -> Void, dismissCompletion: @escaping () -> Void) {
        self.errorFromServerSidePaymentCapture = error
        retryFromServerSidePaymentCaptureError = tryAgain
        dismissServerSidePaymentCaptureErrorCompletion = dismissCompletion
    }

    func nonRetryableError(from: UIViewController?, error: Error, dismissCompletion: @escaping () -> Void) {
        nonRetryableErrorWasCalled = true
        dismissErrorCompletion = dismissCompletion
    }

    func retryableError(from: UIViewController?, tryAgain: @escaping () -> Void) {
        // no-op
    }
}
