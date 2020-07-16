
import Foundation
import MessageUI

/// Presents the MessageUI-provided dialog for sending SMS.
///
/// This should ideally be kept as a service/singleton because it needs to be able to **dismiss**
/// the presented `MFMessageComposeViewController` manually. The `MFMessageComposeViewController.delegate`
/// property is an `unowned` reference. So, if we set that `delegate` to class that can be
/// deallocated, a crash will happen when the user closes the SMS dialog.
///
final class MessageComposerPresenter: NSObject {
    private var presentedViewControllers = Set<MFMessageComposeViewController>()

    deinit {
        // Dismiss any presented ViewControllers that was not dismissed.
        presentedViewControllers.forEach {
            $0.dismiss(animated: false, completion: nil)
        }
        presentedViewControllers.removeAll()
    }

    /// Present a new `MFMessageComposeViewController`.
    ///
    /// Nothing will be presented if the current device does not support SMS.
    ///
    /// - Parameter recipient: The initial value of the "To" field. Possibly a phone number.
    ///
    func presentIfPossible(from presentingViewController: UIViewController, recipient: String) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }

        let controller = MFMessageComposeViewController()
        controller.recipients = [recipient]
        controller.messageComposeDelegate = self

        presentingViewController.present(controller, animated: true, completion: nil)

        presentedViewControllers.insert(controller)
    }
}

extension MessageComposerPresenter: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)

        presentedViewControllers.remove(controller)
    }
}
