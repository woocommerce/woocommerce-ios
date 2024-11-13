import Foundation
import MessageUI

enum CardReaderTransactionAlertEmailReceiptAction {
    case emailSent(String)
    case sendEmail(() -> Void)
    case noEmail

    init(callback: @escaping () -> Void) {
        if MFMailComposeViewController.canSendMail() {
            self = .sendEmail(callback)
        } else {
            self = .noEmail
        }
    }
}
