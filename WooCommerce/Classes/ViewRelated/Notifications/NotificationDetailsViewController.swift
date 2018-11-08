import Foundation
import UIKit
import Yosemite


// MARK: - NotificationDetailsViewController
//
class NotificationDetailsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private var tableView: UITableView!

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Note> = {
        return EntityListener(storageManager: AppDelegate.shared.storageManager, readOnlyEntity: note)
    }()

    /// Note to be displayed!
    ///
    private var note: Note! {
        didSet {
            buildDetailsRows()
        }
    }

    /// DetailsRow(s): Each Row is mapped to a single UI Entity!
    ///
    private var rows = [NoteDetailsRow]()



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
        configureEntityListener()

        buildDetailsRows()
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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Setup: Main View
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] note in
            self?.note = note
        }

        entityListener.onDelete = { [weak self] in
            guard let `self` = self else {
                return
            }

            self.navigationController?.popViewController(animated: true)
            self.displayNoteDeletedNotice()
        }
    }
}


// MARK: - Private Methods
//
private extension NotificationDetailsViewController {

    /// Reloads all of the Notification Detail Rows!
    ///
    func buildDetailsRows() {
        rows = NoteDetailsRow.details(from: note)
        tableView.reloadData()
    }


    /// Displays a Notice onScreen, indicating that the current Note has been deleted from the Store.
    ///
    func displayNoteDeletedNotice() {
        let title = NSLocalizedString("Deleted Notification!", comment: "Deleted Notification's Title")
        let message = NSLocalizedString("The notification has been removed!", comment: "Displayed whenever a Notification that was onscreen got deleted.")
        let notice = Notice(title: title, message: message, feedbackType: .error)

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: UITableViewDataSource Conformance
//
extension NotificationDetailsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

/// TODO:
///     Header:     [.header]
///     Comment:    [OLD Comment Cell + Text + Actions]
///     Regular:    [.image, .text, .user]

        return UITableViewCell(style: .default, reuseIdentifier: "")
    }
}



// MARK: UITableViewDelegate Conformance
//
extension NotificationDetailsViewController: UITableViewDelegate {

}
