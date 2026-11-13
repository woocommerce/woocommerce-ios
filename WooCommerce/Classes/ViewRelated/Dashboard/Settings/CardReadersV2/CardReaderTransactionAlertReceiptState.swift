import Foundation
import MessageUI

enum CardReaderTransactionAlertReceiptState: Sendable {
    case paymentSuccessEmailSent(email: String, printReceiptAction: @MainActor @Sendable () -> Void, noReceiptAction: @MainActor @Sendable () -> Void)
    case promptToSendEmailReceipt(printReceiptAction: @MainActor @Sendable () -> Void,
                                  emailReceiptAction: @MainActor @Sendable () -> Void,
                                  noReceiptAction: @MainActor @Sendable () -> Void)
    case emailSendingNotSupported(printReceiptAction: @MainActor @Sendable () -> Void, noReceiptAction: @MainActor @Sendable () -> Void)

    @MainActor
    init(printReceipt: @escaping @MainActor @Sendable () -> Void,
         emailReceipt: @escaping @MainActor @Sendable () -> Void,
         noReceiptAction: @escaping @MainActor @Sendable () -> Void
    ) {
        if MFMailComposeViewController.canSendMail() {
            self = .promptToSendEmailReceipt(printReceiptAction: printReceipt, emailReceiptAction: emailReceipt, noReceiptAction: noReceiptAction)
        } else {
            self = .emailSendingNotSupported(printReceiptAction: printReceipt, noReceiptAction: noReceiptAction)
        }
    }

    var noReceiptAction: @MainActor @Sendable () -> Void {
        switch self {
        case .paymentSuccessEmailSent(_, _, let noReceiptAction),
                .promptToSendEmailReceipt(_, _, let noReceiptAction),
                .emailSendingNotSupported(_, let noReceiptAction):
            return noReceiptAction
        }
    }
}

/// Failure receipts are automatically sent from WooPayments 8.6 and WooCommerce 9.5 when payment fails and customer is attached
/// Failure receipts can be sent manually from WooCommerce 9.5 via the API
///
enum CardReaderTransactionFailureAlertReceiptState: Sendable {
    case paymentSuccessEmailSent(email: String)
    case promptToSendEmailReceipt(emailReceiptAction: @MainActor @Sendable () -> Void)
    case noEmailReceipt
}
