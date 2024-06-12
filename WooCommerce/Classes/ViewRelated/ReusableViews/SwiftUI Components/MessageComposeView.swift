import SwiftUI
import UIKit
import MessageUI

/// SwiftUI wrapper of `MFMessageComposeViewController`.
/// Its interface lets the user compose and send text messages.
struct MessageComposeView: UIViewControllerRepresentable {

    /// Phone number to set as recipient
    let phone: String?

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MessageComposeView>) -> MFMessageComposeViewController {
        let message = MFMessageComposeViewController()
        message.messageComposeDelegate = context.coordinator

        if let phone {
            message.recipients = [phone]
        }

        return message
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController,
                                context: UIViewControllerRepresentableContext<MessageComposeView>) {

    }

    /// Returns a Boolean that indicates whether the current device is able to send a text.
    ///
    /// You should call this method before attempting to display the message composition interface.
    /// If it returns false, you must not display the message composition interface.
    ///
    static func canSendMessage() -> Bool {
        MFMessageComposeViewController.canSendText()
    }
}
