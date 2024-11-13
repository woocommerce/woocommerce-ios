import Foundation
import MessageUI

enum CardReaderTransactionAlertEmailReceiptAction {
    case emailSent(String)
    case sendEmail(() -> Void)
    case noEmail

    init(email: String? = nil, callback: @escaping () -> Void) {
        if let email = email, email.isNotEmpty {
            self = .emailSent(email)
        } else if MFMailComposeViewController.canSendMail() {
            self = .sendEmail(callback)
        } else {
            self = .noEmail
        }
    }
}
