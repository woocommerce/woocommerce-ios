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
        configureTableView()
        configureEntityListener()

        registerTableViewCells()
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

    /// Setup: TableView
    ///
    func configureTableView() {
        // Hide "Empty Rows"
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] note in
            self?.note = note
        }

        entityListener.onDelete = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
            self?.displayNoteDeletedNotice()
        }
    }

    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [NoteDetailsHeaderTableViewCell.self, NoteDetailsCommentTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
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


    /// Returns the DetailsRow at a given IndexPath.
    ///
    func detailsForRow(at indexPath: IndexPath) -> NoteDetailsRow {
        return rows[indexPath.row]
    }
}


// MARK: UITableViewDataSource Conformance
//
extension NotificationDetailsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = detailsForRow(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)

        setup(cell: cell, at: row)

        return cell
    }
}


// MARK: UITableViewDelegate Conformance
//
extension NotificationDetailsViewController: UITableViewDelegate {

}


// MARK: - Cell Setup
//
private extension NotificationDetailsViewController {

    /// Main Cell Setup Method
    ///
    func setup(cell: UITableViewCell, at row: NoteDetailsRow) {
        switch row {
        case .header:
            setupHeaderCell(cell, at: row)
        case .comment:
            setupCommentCell(cell, at: row)
        }
    }


    /// Setup: Header Cell
    ///
    func setupHeaderCell(_ cell: UITableViewCell, at row: NoteDetailsRow) {
        guard let headerCell = cell as? NoteDetailsHeaderTableViewCell,
            case let .header(gravatarBlock, _) = row else {
                return
        }

        let formatter = StringFormatter()
        headerCell.textLabel?.attributedText = formatter.format(block: gravatarBlock, with: .header)
    }


    /// Setup: Comment Cell
    ///
    func setupCommentCell(_ cell: UITableViewCell, at row: NoteDetailsRow) {
        guard let commentCell = cell as? NoteDetailsCommentTableViewCell,
            case let .comment(commentBlock, userBlock, _) = row else {
                return
        }

        let formatter = StringFormatter()
        commentCell.titleText = userBlock.text
        commentCell.detailsText = note.timestampAsDate.mediumString()
        commentCell.commentAttributedText = formatter.format(block: commentBlock, with: .body)

        // Download the Gravatar
        let gravatarURL = userBlock.media.first?.url
        commentCell.downloadGravatar(with: gravatarURL)
    }
}
