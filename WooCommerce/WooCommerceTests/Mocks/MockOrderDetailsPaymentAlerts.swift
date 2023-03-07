@testable import WooCommerce
import Yosemite
import UIKit

/// Mock for `OrderDetailsPaymentAlertsProtocol`.
final class MockOrderDetailsPaymentAlerts {
    // Public closures to mock alert actions and properties for assertions.
    var cancelPreparingReaderAlert: (() -> Void)?

    var cancelTapOrInsertCardAlert: (() -> Void)?

    var error: Error?
    var retryFromError: (() -> Void)?
    var dismissErrorCompletion: (() -> Void)?
    var nonRetryableErrorWasCalled = false

    // Success alert.
    var printReceiptFromSuccessAlert: (() -> Void)?
    var emailReceiptFromSuccessAlert: (() -> Void)?
}

extension MockOrderDetailsPaymentAlerts: OrderDetailsPaymentAlertsProtocol {
    func preparingReader(onCancel: @escaping () -> Void) {
        cancelPreparingReaderAlert = onCancel
    }

    func presentViewModel(viewModel: CardPresentPaymentsModalViewModel) {
        // no-op
    }

    func tapOrInsertCard(title: String, amount: String, inputMethods: Yosemite.CardReaderInput, onCancel: @escaping () -> Void) {
        cancelTapOrInsertCardAlert = onCancel
    }

    func displayReaderMessage(message: String) {
        // no-op
    }

    func processingPayment(title: String) {
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

    func nonRetryableError(from: UIViewController?, error: Error, dismissCompletion: @escaping () -> Void) {
        nonRetryableErrorWasCalled = true
        dismissErrorCompletion = dismissCompletion
    }

    func retryableError(from: UIViewController?, tryAgain: @escaping () -> Void) {
        // no-op
    }
}
