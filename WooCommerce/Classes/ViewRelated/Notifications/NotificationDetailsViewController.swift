import Foundation
import UIKit
import Yosemite


// MARK: - NotificationDetailsViewController
//
class NotificationDetailsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private var tableView: UITableView!

    /// Note to be displayed!
    ///
    private var note: Note!

    /// Designated Initializer
    ///
    init(note: Note) {
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }

    /// Required!
    ///
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        assert(note != nil, "Please use the designated initializer!")
    }


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItem()
        configureMainView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)


/// Header: [.header]
/// Comment: [OLD Comment Cell + Text + Actions]
/// Regular: [.image, .text, .user]
    }
}


// MARK: - User Interface Initialization
//
private extension NotificationDetailsViewController {

    /// Setup: Navigation
    ///
    func configureNavigationItem() {
        title = note.title

        // Don't show the Notifications title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
    }

    /// Setup: Main View
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }
}
