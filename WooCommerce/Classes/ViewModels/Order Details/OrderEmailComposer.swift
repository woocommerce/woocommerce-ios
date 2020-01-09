import Yosemite
import MessageUI

/// Encapsulates logic to share an Order via email
///
final class OrderEmailComposer: NSObject, MFMailComposeViewControllerDelegate {
    func displayEmailComposerIfPossible(for order: Order, from: UIViewController) -> Bool {
        guard let email = order.billingAddress?.email, MFMailComposeViewController.canSendMail() else {
            return false
        }

        displayEmailComposer(for: email, from: from)
        ServiceLocator.analytics.track(.orderContactAction, withProperties: ["id": order.orderID,
                                                                        "status": order.statusKey,
                                                                        "type": "email"])

        return MFMailComposeViewController.canSendMail()
    }

    private func displayEmailComposer(for email: String, from: UIViewController) {
        // Workaround: MFMailCompose isn't *FULLY* picking up UINavigationBar's WC's appearance. Title / Buttons look awful.
        // We're falling back to iOS's default appearance
        UINavigationBar.applyDefaultAppearance()

        // Composer
        let controller = MFMailComposeViewController()
        controller.setToRecipients([email])
        controller.mailComposeDelegate = self
        from.present(controller, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)

        // Workaround: Restore WC's navBar appearance
        UINavigationBar.applyWooAppearance()
    }
}
