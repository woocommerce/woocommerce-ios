import Yosemite
import MessageUI

final class OrderMessgeComposer: NSObject, MFMessageComposeViewControllerDelegate {
    func displayMessageComposerIfPossible(order: Order, from: UIViewController) {
        guard let phoneNumber = order.billingAddress?.cleanedPhoneNumber,
            MFMessageComposeViewController.canSendText()
            else {
                return
        }

        displayMessageComposer(for: phoneNumber, from: from)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": order.orderID,
                                                                        "status": order.statusKey,
                                                                        "type": "sms"])
    }

    private func displayMessageComposer(for phoneNumber: String, from: UIViewController) {
        let controller = MFMessageComposeViewController()
        controller.recipients = [phoneNumber]
        controller.messageComposeDelegate = self
        from.present(controller, animated: true, completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
