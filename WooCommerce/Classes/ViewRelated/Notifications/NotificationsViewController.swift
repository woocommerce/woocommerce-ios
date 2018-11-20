import UIKit
import Gridicons
import Yosemite
import WordPressUI
import SafariServices
import Gridicons


// MARK: - NotificationsViewController
//
class NotificationsViewController: UIViewController {

    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// Haptic Feedback!
    ///
    private let hapticGenerator = UINotificationFeedbackGenerator()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Notes in sync.
    ///
    private lazy var resultsController: ResultsController<StorageNote> = {
        let storageManager = AppDelegate.shared.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageNote.timestamp, ascending: false)

        return ResultsController<StorageNote>(storageManager: storageManager, sectionNameKeyPath: "normalizedAgeAsString", matching: filter, sortedBy: [descriptor])
    }()

    /// Store Notifications CoreData Filter.
    ///
    private var filter: NSPredicate {
        let typePredicate = NSPredicate(format: "type == %@ OR subtype == %@", Note.Kind.storeOrder.rawValue, Note.Subkind.storeReview.rawValue)
        let sitePredicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [typePredicate, sitePredicate])
    }

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Rendered Subjects Cache.
    ///
    private var subjectStorage = [Int64: NSAttributedString]()

    /// Rendered Snippet Cache.
    ///
    private var snippetStorage = [Int64: NSAttributedString]()

    /// String Formatter: Given a NoteBlock, this tool will return an AttributedString.
    ///
    private let formatter = StringFormatter()

    /// UI Active State
    ///
    private var state: State = .results {
        didSet {
            guard oldValue != state else {
                return
            }

            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        return resultsController.isEmpty
    }

    /// The current unread Notes.
    ///
    private var unreadNotes: [Note] {
        return resultsController.fetchedObjects.filter { $0.read == false }
    }

    // MARK: - View Lifecycle

    deinit {
        stopListeningToNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureTabBarItem()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StyleManager.tableViewBackgroundColor

        configureNavigationItem()
        configureNavigationBarButtons()
        configureTableView()
        configureTableViewCells()
        configureResultsController()

        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        synchronizeNotifications()
    }
}


// MARK: - User Interface Initialization
//
private extension NotificationsViewController {

    /// Setup: TabBar
    ///
    func configureTabBarItem() {
        tabBarItem.title = NSLocalizedString("Notifications", comment: "Notifications tab title")
        tabBarItem.image = Gridicon.iconOfType(.bell)
    }

    /// Setup: Navigation
    ///
    func configureNavigationItem() {
        // Don't show the Settings title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Setup: NavigationBar Buttons
    ///
    func configureNavigationBarButtons() {
        let leftBarButton = UIBarButtonItem(image: Gridicon.iconOfType(.checkmark),
                                             style: .plain,
                                             target: self,
                                             action: #selector(markAllAsRead))
        leftBarButton.tintColor = .white
        leftBarButton.accessibilityTraits = .button
        leftBarButton.accessibilityLabel = NSLocalizedString("Mark All as Read", comment: "Accessibility label for the Mark All Notifications as Read Button")
        leftBarButton.accessibilityHint = NSLocalizedString("Marks Every Notification as Read", comment: "VoiceOver accessibility hint for the Mark All Notifications as Read Action")
        navigationItem.leftBarButtonItem = leftBarButton
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
    }

    /// Setup: ResultsController
    ///
    func configureResultsController() {
        resultsController.startForwardingEvents(to: tableView)
        resultsController.onDidChangeContent = { [weak self] in
            // FIXME: This should be removed once `PushNotificationsManager` is in place
            self?.updateNotificationsTabIfNeeded()
        }
        resultsController.onDidResetContent = {
            // FIXME: This should be removed once `PushNotificationsManager` is in place
            MainTabBarController.hideDotOn(.notifications)
        }
        try? resultsController.performFetch()
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells() {
        let cells = [NoteTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}


// MARK: - Actions
//
private extension NotificationsViewController {

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        WooAnalytics.shared.track(.notificationsListPulledToRefresh)
        synchronizeNotifications {
            sender.endRefreshing()
        }
    }

    @IBAction func markAllAsRead() {
        if unreadNotes.isEmpty {
            DDLogVerbose("# Every single notification is already marked as Read!")
            return
        }

        markAsRead(notes: unreadNotes)
        hapticGenerator.notificationOccurred(.success)
    }
}


// MARK: - Yosemite Wrappers
//
private extension NotificationsViewController {

    /// Marks the specified collection of Notifications as Read.
    ///
    func markAsRead(notes: [Note]) {
        let identifiers = notes.map { $0.noteId }
        let action = NotificationAction.updateMultipleReadStatus(noteIds: identifiers, read: true) { error in
            if let error = error {
                DDLogError("⛔️ Error marking notifications as read: \(error)")
            }
        }

        StoresManager.shared.dispatch(action)
    }

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    func synchronizeNotifications(onCompletion: (() -> Void)? = nil) {
        let action = NotificationAction.synchronizeNotifications { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing notifications: \(error)")
            }

            self.transitionToResultsUpdatedState()
            onCompletion?()
        }

        transitionToSyncingState()
        StoresManager.shared.dispatch(action)
    }
}


// MARK: - ResultsController
//
extension NotificationsViewController {

    /// Refreshes the Results Controller Predicate, and ensures the UI is in Sync.
    ///
    func reloadResultsController() {
        resultsController.predicate = filter
        tableView.reloadData()
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension NotificationsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteTableViewCell.reuseIdentifier) as? NoteTableViewCell else {
            fatalError()
        }

        configure(cell, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let rawAge = resultsController.sections[section].name
        return Age(rawValue: rawAge)?.description
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension NotificationsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let note = resultsController.object(at: indexPath)

        switch note.kind {
        case .storeOrder:
            presentOrderDetails(for: note)
        default:
            presentNotificationDetails(for: note)
        }
    }
}


// MARK: - Details Rendering
//
private extension NotificationsViewController {

    /// Pushes the Order Details associated to a given Note (if possible).
    ///
    func presentOrderDetails(for note: Note) {
        guard let orderID = note.meta.identifier(forKey: .order), let siteID = note.meta.identifier(forKey: .site) else {
            DDLogError("## Notification with [\(note.noteId)] lacks its OrderID!")
            return
        }

        let loaderViewController = OrderLoaderViewController(orderID: orderID, siteID: siteID)
        navigationController?.pushViewController(loaderViewController, animated: true)
    }

    /// Pushes the Notification Details associated to a given Note.
    ///
    func presentNotificationDetails(for note: Note) {
        let detailsViewController = NotificationDetailsViewController(note: note)
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
}


// MARK: - Cell Setup
//
private extension NotificationsViewController {

    /// Initializes the Notifications Cell at the specified indexPath
    ///
    func configure(_ cell: NoteTableViewCell, at indexPath: IndexPath) {
        let note = resultsController.object(at: indexPath)

        cell.read = note.read
        cell.noticon = note.noticon
        cell.attributedSubject = renderSubject(note: note)
        cell.attributedSnippet = renderSnippet(note: note)
    }
}


// MARK: - Formatting
//
private extension NotificationsViewController {

    /// Returns the formatted Subject (if any). For performance reasons, we'll cache the result.
    ///
    func renderSubject(note: Note) -> NSAttributedString? {
        if let cached = subjectStorage[note.hash] {
            return cached
        }

        let subject = note.blockForSubject.map { formatter.format(block: $0, with: .subject) }
        subjectStorage[note.hash] = subject

        return subject
    }

    /// Returns the formatted Snippet (if any). For performance reasons, we'll cache the result.
    ///
    func renderSnippet(note: Note) -> NSAttributedString? {
        if let cached = snippetStorage[note.hash] {
            return cached
        }

        let snippet = note.blockForSnippet.map { formatter.format(block: $0, with: .snippet) }
        snippetStorage[note.hash] = snippet

        return snippet
    }
}


// MARK: - Placeholders
//
private extension NotificationsViewController {

    /// Renders Placeholder Notes: For safety reasons, we'll also halt ResultsController <> UITableView glue.
    ///
    func displayPlaceholderNotes() {
        let options = GhostOptions(reuseIdentifier: NoteTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options)

        resultsController.stopForwardingEvents()
    }

    /// Removes Placeholder Notes (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderNotes() {
        tableView.removeGhostContent()
        resultsController.startForwardingEvents(to: self.tableView)
    }

    /// Displays the Empty State Overlay.
    ///
    func displayEmptyNotesOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = .waitingForCustomersImage
        overlayView.messageText = NSLocalizedString("No Notifications Yet!", comment: "Empty Notifications List Message")
        overlayView.actionText = NSLocalizedString("Share your Store", comment: "Action: Opens the Store in a browser")
        overlayView.onAction = { [weak self] in
            self?.displayDefaultSite()
        }

        overlayView.attach(to: view)
    }

    /// Removes all of the the OverlayMessageView instances in the view hierarchy.
    ///
    func removeAllOverlays() {
        for subview in view.subviews where subview is OverlayMessageView {
            subview.removeFromSuperview()
        }
    }

    /// Displays the Default Site in a WebView.
    ///
    func displayDefaultSite() {
        guard let urlAsString = StoresManager.shared.sessionManager.defaultSite?.url, let siteURL = URL(string: urlAsString) else {
            return
        }

        let safariViewController = SFSafariViewController(url: siteURL)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }
}


// MARK: - Notifications
//
extension NotificationsViewController {

    /// Setup: Notification Hooks
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultSiteWasUpdated), name: .StoresManagerDidUpdateDefaultSite, object: nil)
    }

    /// Tear down the Notifications Hooks
    ///
    func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    /// Default Site Updated Handler
    ///
    @objc func defaultSiteWasUpdated() {
        reloadResultsController()
    }
}


// MARK: - Finite State Machine Management
//
private extension NotificationsViewController {

    /// Runs whenever the FSM enters a State.
    ///
    func didEnter(state: State) {
        switch state {
        case .empty:
            displayEmptyNotesOverlay()
        case .results:
            break
        case .syncing:
            displayPlaceholderNotes()
        }
    }

    /// Runs whenever the FSM leaves a State.
    ///
    func didLeave(state: State) {
        switch state {
        case .empty:
            removeAllOverlays()
        case .results:
            break
        case .syncing:
            removePlaceholderNotes()
        }
    }

    /// Should be called before Sync'ing Starts: Transitions to .results / .syncing
    ///
    func transitionToSyncingState() {
        state = isEmpty ? .syncing : .results
    }

    /// Should be called after Sync'ing wraps up: Transitions to .empty / .results
    ///
    func transitionToResultsUpdatedState() {
        state = isEmpty ? .empty : .results
    }
}


// MARK: - Private Helpers
//
private extension NotificationsViewController {

    // FIXME: This should be removed once `PushNotificationsManager` is in place
    func updateNotificationsTabIfNeeded() {
        guard !unreadNotes.isEmpty else {
            MainTabBarController.hideDotOn(.notifications)
            return
        }
        
        MainTabBarController.showDotOn(.notifications)
    }
}


// MARK: - Nested Types
//
private extension NotificationsViewController {

    enum Settings {
        static let placeholderRowsPerSection = [3]
    }

    enum State {
        case empty
        case results
        case syncing
    }
}
