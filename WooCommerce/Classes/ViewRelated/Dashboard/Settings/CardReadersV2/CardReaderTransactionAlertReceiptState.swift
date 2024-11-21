import Foundation
import MessageUI

enum CardReaderTransactionAlertReceiptState {
    case paymentSuccessEmailSent(email: String, printReceiptAction: () -> Void, noReceiptAction: () -> Void)
    case promptToSendEmailReceipt(printReceiptAction: () -> Void, emailReceiptAction: () -> Void, noReceiptAction: () -> Void)
    case emailSendingNotSupported(printReceiptAction: () -> Void, noReceiptAction: () -> Void)

    init(printReceipt: @escaping () -> Void,
         emailReceipt: @escaping () -> Void,
         noReceiptAction: @escaping () -> Void
    ) {
        if MFMailComposeViewController.canSendMail() {
            self = .promptToSendEmailReceipt(printReceiptAction: printReceipt, emailReceiptAction: emailReceipt, noReceiptAction: noReceiptAction)
        } else {
            self = .emailSendingNotSupported(printReceiptAction: printReceipt, noReceiptAction: noReceiptAction)
        }
    }

    var noReceiptAction: () -> Void {
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
enum CardReaderTransactionFailureAlertReceiptState {
    case paymentSuccessEmailSent(email: String)
    case promptToSendEmailReceipt(emailReceiptAction: () -> Void)
    case noEmailReceipt
}
