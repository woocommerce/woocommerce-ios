import SwiftUI
import UIKit
import MessageUI

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

    static func canSendEmail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }
}
