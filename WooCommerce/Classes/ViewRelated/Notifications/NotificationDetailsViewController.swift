import Foundation
import UIKit
import Yosemite
import Gridicons


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

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Note to be displayed!
    ///
    private var note: Note! {
        didSet {
            reloadInterface()
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
        reloadInterface()
    }
}


// MARK: - User Interface Initialization
//
private extension NotificationDetailsViewController {

    /// Setup: Navigation
    ///
    func configureNavigationItem() {
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
        tableView.refreshControl = refreshControl
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
        let cells = [
            NoteDetailsHeaderTableViewCell.self,
            NoteDetailsHeaderPlainTableViewCell.self,
            NoteDetailsCommentTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}


// MARK: - Sync
//
private extension NotificationDetailsViewController {

    /// Refresh Control's Callback.
    ///
    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        WooAnalytics.shared.track(.notificationsListPulledToRefresh)

        synchronizeNotification(noteId: note.noteId) {
            sender.endRefreshing()
        }
    }

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    func synchronizeNotification(noteId: Int64, onCompletion: @escaping () -> Void) {
        let action = NotificationAction.synchronizeNotification(noteId: noteId) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing notification [\(noteId)]: \(error)")
            }

            onCompletion()
        }

        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Display Notices
//
private extension NotificationDetailsViewController {

    /// Displays a Notice onScreen, indicating that the current Note has been deleted from the Store.
    ///
    func displayNoteDeletedNotice() {
        let title = NSLocalizedString("Notification", comment: "Deleted Notification's Title")
        let message = NSLocalizedString("The notification has been removed", comment: "Displayed whenever a Notification that was onscreen got deleted.")
        let notice = Notice(title: title, message: message, feedbackType: .error)

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the Error Notice.
    ///
    static func displayModerationErrorNotice(failedStatus: CommentStatus) {
        let title = NSLocalizedString("Notification Error", comment: "Notification error notice title")
        let message = String.localizedStringWithFormat(NSLocalizedString("Unable to mark the notification as %@",
                                                                         comment: "Notification error notice message"), failedStatus.description)
        let notice = Notice(title: title, message: message, feedbackType: .error)

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the `Comment moderated` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    static func displayModerationCompleteNotice(newStatus: CommentStatus, onUndoAction: @escaping () -> Void) {
        guard newStatus != .unknown else {
            return
        }

        let title = NSLocalizedString("Notification", comment: "Notification notice title")
        let message = String.localizedStringWithFormat(NSLocalizedString("Notification marked as %@",
                                                                         comment: "Notification moderation success notice message"), newStatus.description)
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: title, message: message, feedbackType: .success, actionTitle: actionTitle, actionHandler: onUndoAction)

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Private Methods
//
private extension NotificationDetailsViewController {

    /// Reloads all of the Details Interface
    ///
    func reloadInterface() {
        title = note.title
        rows = NoteDetailsRow.details(from: note)
        tableView.reloadData()
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
        case .headerPlain:
            setupHeaderPlainCell(cell, at: row)
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


    /// Setup: Header Cell (Plain)
    ///
    func setupHeaderPlainCell(_ cell: UITableViewCell, at row: NoteDetailsRow) {
        guard let headerCell = cell as? NoteDetailsHeaderPlainTableViewCell,
            case let .headerPlain(title) = row else {
                return
        }

        headerCell.leftImage = Gridicon.iconOfType(.product)
        headerCell.rightImage = Gridicon.iconOfType(.external)
        headerCell.plainText = title
    }


    /// Setup: Comment Cell
    ///
    func setupCommentCell(_ cell: UITableViewCell, at row: NoteDetailsRow) {
        guard let commentCell = cell as? NoteDetailsCommentTableViewCell,
            case let .comment(commentBlock, userBlock, _) = row else {
                return
        }

        // Setup: Properties
        let formatter = StringFormatter()
        commentCell.titleText = userBlock.text
        commentCell.detailsText = note.timestampAsDate.mediumString()
        commentCell.commentAttributedText = formatter.format(block: commentBlock, with: .body)
        commentCell.starRating = note.starRating

        let gravatarURL = userBlock.media.first?.url
        commentCell.downloadGravatar(with: gravatarURL)

        commentCell.isApproveEnabled  = commentBlock.isActionEnabled(.approve)
        commentCell.isTrashEnabled    = commentBlock.isActionEnabled(.trash)
        commentCell.isSpamEnabled     = commentBlock.isActionEnabled(.spam)
        commentCell.isApproveSelected = commentBlock.isActionOn(.approve)

        // Setup: Callbacks
        if let commentID = commentBlock.meta.identifier(forKey: .comment),
            let siteID = commentBlock.meta.identifier(forKey: .site) {

            commentCell.onSpam = { [weak self] in
                WooAnalytics.shared.track(.notificationReviewSpamTapped)
                WooAnalytics.shared.track(.notificationReviewAction, withProperties: ["type": CommentStatus.spam.rawValue])
                self?.moderateComment(siteID: siteID, commentID: commentID, doneStatus: .spam, undoStatus: .unspam)
            }

            commentCell.onTrash = { [weak self] in
                WooAnalytics.shared.track(.notificationReviewTrashTapped)
                WooAnalytics.shared.track(.notificationReviewAction, withProperties: ["type": CommentStatus.trash.rawValue])
                self?.moderateComment(siteID: siteID, commentID: commentID, doneStatus: .trash, undoStatus: .untrash)
            }

            commentCell.onApprove = { [weak self] in
                WooAnalytics.shared.track(.notificationReviewApprovedTapped)
                WooAnalytics.shared.track(.notificationReviewAction, withProperties: ["type": CommentStatus.approved.rawValue])
                self?.moderateComment(siteID: siteID, commentID: commentID, doneStatus: .approved, undoStatus: .unapproved)
            }

            commentCell.onUnapprove = { [weak self] in
                WooAnalytics.shared.track(.notificationReviewApprovedTapped)
                WooAnalytics.shared.track(.notificationReviewAction, withProperties: ["type": CommentStatus.unapproved.rawValue])
                self?.moderateComment(siteID: siteID, commentID: commentID, doneStatus: .unapproved, undoStatus: .approved)
            }
        }
    }
}


// MARK: - Comment Moderation
//
private extension NotificationDetailsViewController {

    /// Dispatches the moderation command (Approve/Unapprove, Spam, Trash) to the backend
    ///
    func moderateComment(siteID: Int, commentID: Int, doneStatus: CommentStatus, undoStatus: CommentStatus) {
        guard let undo = moderateCommentAction(siteID: siteID, commentID: commentID, status: undoStatus, onCompletion: { (error) in
            guard let error = error else {
                WooAnalytics.shared.track(.notificationReviewActionSuccess)
                return
            }

            DDLogError("⛔️ Comment (UNDO) moderation failure for ID: \(commentID) attempting \(doneStatus.description) status. Error: \(error)")

            // FIXME: Uncomment this error notice + Tracks call 👇 once we figure out why the server is return errors constantly 😭
            //WooAnalytics.shared.track(.notificationReviewActionFailed, withError: error)
            //NotificationDetailsViewController.displayModerationErrorNotice(failedStatus: undoStatus)
        }) else {
            return
        }

        guard let done = moderateCommentAction(siteID: siteID, commentID: commentID, status: doneStatus, onCompletion: { (error) in
            guard let error = error else {
                WooAnalytics.shared.track(.notificationReviewActionSuccess)
                NotificationDetailsViewController.displayModerationCompleteNotice(newStatus: doneStatus, onUndoAction: {
                    WooAnalytics.shared.track(.notificationReviewActionUndo)
                    StoresManager.shared.dispatch(undo)
                })
                return
            }

            DDLogError("⛔️ Comment moderation failure for ID: \(commentID) attempting \(doneStatus.description) status. Error: \(error)")

            // FIXME: Uncomment this error notice + Tracks call 👇 once we figure out why the server is return errors constantly 😭
            //WooAnalytics.shared.track(.notificationReviewActionFailed, withError: error)
            //NotificationDetailsViewController.displayModerationErrorNotice(failedStatus: doneStatus)
        }) else {
            return
        }

        StoresManager.shared.dispatch(done)
        navigationController?.popViewController(animated: true)
    }

    /// Returns an comment moderation action that will result in the specified comment being updated accordingly.
    ///
    func moderateCommentAction(siteID: Int, commentID: Int, status: CommentStatus, onCompletion: @escaping (Error?) -> Void) -> [Action]? {
        let noteID = note.noteId

        switch status {
        case .approved:
            return [CommentAction.updateApprovalStatus(siteID: siteID, commentID: commentID, isApproved: true, onCompletion: { (_, error) in onCompletion(error) })]
        case .unapproved:
            return [CommentAction.updateApprovalStatus(siteID: siteID, commentID: commentID, isApproved: false, onCompletion: { (_, error) in onCompletion(error) })]
        case .spam:
            return [locallyDeletedStatusAction(noteID: noteID, deleteInProgress: true),
                    CommentAction.updateSpamStatus(siteID: siteID, commentID: commentID, isSpam: true, onCompletion: { (_, error) in onCompletion(error) })]
        case .unspam:
            return [locallyDeletedStatusAction(noteID: noteID, deleteInProgress: false),
                    CommentAction.updateSpamStatus(siteID: siteID, commentID: commentID, isSpam: false, onCompletion: { (_, error) in onCompletion(error) })]
        case .trash:
            return [locallyDeletedStatusAction(noteID: noteID, deleteInProgress: true),
                    CommentAction.updateTrashStatus(siteID: siteID, commentID: commentID, isTrash: true, onCompletion: { (_, error) in onCompletion(error) })]
        case .untrash:
            return [locallyDeletedStatusAction(noteID: noteID, deleteInProgress: false),
                    CommentAction.updateTrashStatus(siteID: siteID, commentID: commentID, isTrash: false, onCompletion: { (_, error) in onCompletion(error) })]
        case .unknown:
            DDLogError("⛔️ Comment moderation failure: attempted to update comment with unknown status.")
            return nil
        }
    }

    /// Returns a "note pending deletion" action (so the note list removes the deleted note immediately)
    ///
    func locallyDeletedStatusAction(noteID: Int64, deleteInProgress: Bool) -> Action {
        let action = NotificationAction.updateLocalDeletedStatus(noteId: noteID, deleteInProgress: deleteInProgress) { error in
            if error != nil {
                DDLogError("⛔️ Error marking deleteInProgress == \(deleteInProgress) for note \(noteID) locally: \(String(describing: error))")
            }
        }
        return action
    }
}
