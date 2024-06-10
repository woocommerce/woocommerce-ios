import SwiftUI
import UIKit
import MessageUI

/// SwiftUI wrapper of `MFMailComposeViewController`.
/// Its interface lets the user manage, edit, and send email messages.
struct EmailView: UIViewControllerRepresentable {

    /// Email address to set as recipient
    let emailAddress: String?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<EmailView>) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator

        if let emailAddress {
            mail.setToRecipients([emailAddress])
        }

        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<EmailView>) {

    }

    /// Returns a Boolean that indicates whether the current device is able to send email.
    ///
    /// You should call this method before attempting to display the mail composition interface.
    /// If it returns false, you must not display the mail composition interface.
    ///
    static func canSendEmail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }
}
