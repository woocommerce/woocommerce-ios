import Foundation
import UIKit
import Yosemite
import Gridicons
import SafariServices


// MARK: - ReviewDetailsViewController
//
final class ReviewDetailsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private var tableView: UITableView!

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<ProductReview> = {
        return EntityListener(storageManager: ServiceLocator.storageManager, readOnlyEntity: productReview)
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
    private var productReview: ProductReview! {
        didSet {
            reloadInterface()
        }
    }

    private let product: Product?

    /// Sections to be rendered
    ///
    private var rows = [Row]()

    /// Designated Initializer
    ///
    init(productReview: ProductReview, product: Product?) {
        self.productReview = productReview
        self.product = product
        super.init(nibName: nil, bundle: nil)
    }

    /// Required!
    ///
    required init?(coder aDecoder: NSCoder) {
        self.product = nil
        super.init(coder: aDecoder)
        assert(productReview != nil, "Please use the designated initializer!")
    }


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItem()
        configureMainView()
        configureTableView()
        configureEntityListener()
        configureAppRatingEvent()

        registerTableViewCells()
        reloadInterface()
    }
}


// MARK: - User Interface Initialization
//
private extension ReviewDetailsViewController {

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
        tableView.separatorInset = .zero
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] productReview in
            self?.productReview = productReview
        }

        entityListener.onDelete = { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
            self?.displayNoteDeletedNotice()
        }
    }

    /// Reports a significant event to the App Rating Manager
    ///
    func configureAppRatingEvent() {
        AppRatingManager.shared.incrementSignificantEvent(section: Constants.section)
    }

    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            NoteDetailsHeaderPlainTableViewCell.self,
            NoteDetailsCommentTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    func reloadRows() {
        rows = [.header, .content]
    }
}


// MARK: - Sync
//
private extension ReviewDetailsViewController {

    /// Refresh Control's Callback.
    ///
    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.notificationsListPulledToRefresh)

        synchronizeReview(reviewID: productReview.reviewID) {
            sender.endRefreshing()
        }
    }

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    func synchronizeReview(reviewID: Int, onCompletion: @escaping () -> Void) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        let action = ProductReviewAction.retrieveProductReview(siteID: siteID, reviewID: reviewID) { (productReview, error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing product review [\(reviewID)]: \(error)")
            }

            onCompletion()
        }

        ServiceLocator.stores.dispatch(action)
    }
}


// MARK: - Display Notices
//
private extension ReviewDetailsViewController {

    /// Displays a Notice onScreen, indicating that the current Review has been deleted from the Store.
    ///
    func displayNoteDeletedNotice() {
        let title = NSLocalizedString("The review has been removed", comment: "Displayed whenever a review that was onscreen got deleted.")
        let notice = Notice(title: title, feedbackType: .error)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the Error Notice.
    ///
    static func displayModerationErrorNotice(failedStatus: CommentStatus) {
        let message = String.localizedStringWithFormat(
            NSLocalizedString(
                "Unable to mark review as %@",
                comment: "Review error notice message. It reads: Unable to mark review as {attempted status}"
            ),
            failedStatus.description
        )
        let notice = Notice(title: message, feedbackType: .error)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the `Comment moderated` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    static func displayModerationCompleteNotice(newStatus: CommentStatus, onUndoAction: @escaping () -> Void) {
        guard newStatus != .unknown else {
            return
        }

        let message = String.localizedStringWithFormat(
            NSLocalizedString(
                "Review marked as %@",
                comment: "Review moderation success notice message. It reads: Review marked as {new status}"
            ),
            newStatus.description
        )
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: message, feedbackType: .success, actionTitle: actionTitle, actionHandler: onUndoAction)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Private Methods
//
private extension ReviewDetailsViewController {

    /// Reloads all of the Details Interface
    ///
    func reloadInterface() {
        title = Constants.title
        reloadRows()
        tableView.reloadData()
    }

    /// Returns the Row at a given IndexPath.
    ///
    func detailsForRow(at indexPath: IndexPath) -> Row {
        return rows[indexPath.row]
    }
}


// MARK: UITableViewDataSource Conformance
//
extension ReviewDetailsViewController: UITableViewDataSource {

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
extension ReviewDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = detailsForRow(at: indexPath)
        switch row {
        case .header:
            openProductURL()
        default:
            break
        }
    }
}


// MARK: - Cell Setup
//
private extension ReviewDetailsViewController {

    /// Main Cell Setup Method
    ///
    func setup(cell: UITableViewCell, at row: Row) {
        switch row {
        case .header:
            setupHeaderPlainCell(cell)
        case .content:
            setupCommentCell(cell)
        }
    }


    /// Setup: Header Cell (Plain)
    ///
    func setupHeaderPlainCell(_ cell: UITableViewCell) {
        guard let headerCell = cell as? NoteDetailsHeaderPlainTableViewCell else {
            return
        }

        headerCell.leftImage = .productImage
        headerCell.rightImage = .externalImage
        headerCell.plainText = product?.name ?? "Unknown"
    }


    /// Setup: Comment Cell
    ///
    func setupCommentCell(_ cell: UITableViewCell) {
        guard let commentCell = cell as? NoteDetailsCommentTableViewCell else {
                return
        }

        // Setup: Properties
        commentCell.titleText = productReview.reviewer
        commentCell.detailsText = ReviewAge.from(startDate: productReview.dateCreated, toDate: Date()).description
        commentCell.commentAttributedText = NSAttributedString(string: productReview.review.strippedHTML)
        commentCell.starRating = productReview.rating

        //let gravatarURL = userBlock.media.first?.url
        let gravatarURL = URL(string: "https://2.gravatar.com/avatar/b371b7de1e58a5dcc3fc3aa236784081?s=32&d=mm&r=G")
        commentCell.downloadGravatar(with: gravatarURL)

        commentCell.isApproveEnabled  = true
        commentCell.isTrashEnabled    = true
        commentCell.isSpamEnabled     = true
        commentCell.isApproveSelected = productReview.status == .approved

        // Setup: Callbacks
//        if let commentID = commentBlock.meta.identifier(forKey: .comment),
//            let siteID = commentBlock.meta.identifier(forKey: .site) {
//
//            commentCell.onSpam = { [weak self] in
//                ServiceLocator.analytics.track(.notificationReviewSpamTapped)
//                ServiceLocator.analytics.track(.notificationReviewAction, withProperties: ["type": CommentStatus.spam.rawValue])
//                self?.moderateComment(siteID: siteID, commentID: commentID, doneStatus: .spam, undoStatus: .unspam)
//            }
//
//            commentCell.onTrash = { [weak self] in
//                ServiceLocator.analytics.track(.notificationReviewTrashTapped)
//                ServiceLocator.analytics.track(.notificationReviewAction, withProperties: ["type": CommentStatus.trash.rawValue])
//                self?.moderateComment(siteID: siteID, commentID: commentID, doneStatus: .trash, undoStatus: .untrash)
//            }
//
//            commentCell.onApprove = { [weak self] in
//                ServiceLocator.analytics.track(.notificationReviewApprovedTapped)
//                ServiceLocator.analytics.track(.notificationReviewAction, withProperties: ["type": CommentStatus.approved.rawValue])
//                self?.moderateComment(siteID: siteID, commentID: commentID, doneStatus: .approved, undoStatus: .unapproved)
//            }
//
//            commentCell.onUnapprove = { [weak self] in
//                ServiceLocator.analytics.track(.notificationReviewApprovedTapped)
//                ServiceLocator.analytics.track(.notificationReviewAction, withProperties: ["type": CommentStatus.unapproved.rawValue])
//                self?.moderateComment(siteID: siteID, commentID: commentID, doneStatus: .unapproved, undoStatus: .approved)
//            }
//        }
    }
}


// MARK: - Private Methods
//
private extension ReviewDetailsViewController {

    /// Presents a WebView at the product URL
    ///
    func openProductURL() {
        let productURL = product?.externalURL
        WebviewHelper.launch(productURL, with: self)
    }
}

// MARK: - Nested Types
//
private extension ReviewDetailsViewController {
    struct Constants {
        static let section = "notifications"
        static let title = NSLocalizedString("Product Review",
                                             comment: "Title of the view containing a single Product Review")
    }
}


private extension ReviewDetailsViewController {
    enum Row {
        case header
        case content

        var reuseIdentifier: String {
            switch self {
            case .header:
                return NoteDetailsHeaderPlainTableViewCell.reuseIdentifier
            case .content:
                return NoteDetailsCommentTableViewCell.reuseIdentifier
            }
        }
    }

}
