import UIKit


// MARK: - NotificationsViewController
//
class NotificationsViewController: UIViewController {

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StyleManager.tableViewBackgroundColor

        displayPlaceholder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WooAnalytics.shared.track(.notificationsSelected)
    }

    /// Displays the Empty State Overlay.
    ///
    func displayPlaceholder() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = .waitingForCustomersImage
        overlayView.messageText = NSLocalizedString("Notifications aren't ready yet, but\n coming in a future release. Stay tuned!", comment: "Notifications Unavailable Placeholder")
        overlayView.actionVisible = false

        overlayView.attach(to: view)
    }
}
