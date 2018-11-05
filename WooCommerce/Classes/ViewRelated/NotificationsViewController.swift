import UIKit
import Gridicons


// MARK: - NotificationsViewController
//
class NotificationsViewController: UIViewController {

    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!


    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTabBarItem()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StyleManager.tableViewBackgroundColor

        displayPlaceholder()
    }


    /// Setup: TabBar
    ///
    func setupTabBarItem() {
        tabBarItem.title = NSLocalizedString("Notifications", comment: "Notifications tab title")
        tabBarItem.image = Gridicon.iconOfType(.statsAlt)
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
