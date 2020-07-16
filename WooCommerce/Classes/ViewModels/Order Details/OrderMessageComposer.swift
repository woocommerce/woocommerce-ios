import Yosemite
import MessageUI

/// Encapsulates logic necessary to share an Order via Message
///
final class OrderMessageComposer: NSObject, MFMessageComposeViewControllerDelegate {

    private var messageComposeViewController: MFMessageComposeViewController?

    deinit {
        // If this class is dismissed while a `ComposeViewController` is active, a crash will
        // happen because `ComposeViewController.delegate` is an `unowned` reference to `self`.
        messageComposeViewController?.dismiss(animated: false, completion: nil)
    }

    func displayMessageComposerIfPossible(order: Order, from: UIViewController) {
        guard let phoneNumber = order.billingAddress?.cleanedPhoneNumber,
            MFMessageComposeViewController.canSendText()
            else {
                return
        }

        displayMessageComposer(for: phoneNumber, from: from)
        ServiceLocator.analytics.track(.orderContactAction, withProperties: ["id": order.orderID,
                                                                        "status": order.statusKey,
                                                                        "type": "sms"])
    }

    private func displayMessageComposer(for phoneNumber: String, from: UIViewController) {
        // Dismiss in case there is an active ViewController
        messageComposeViewController?.dismiss(animated: false, completion: nil)

        let controller = MFMessageComposeViewController()
        controller.recipients = [phoneNumber]
        controller.messageComposeDelegate = self
        from.present(controller, animated: true, completion: nil)

        messageComposeViewController = controller
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)

        messageComposeViewController = nil
    }
}
