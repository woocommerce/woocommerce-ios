import UIKit
import Gridicons
import Yosemite
import WordPressUI
import SafariServices
import Gridicons
import StoreKit


// MARK: - NotificationsViewController
//
class NotificationsViewController: UIViewController {

    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// Mark all as read nav bar button
    ///
    private lazy var leftBarButton: UIBarButtonItem = {
        return UIBarButtonItem(image: .checkmarkImage,
                               style: .plain,
                               target: self,
                               action: #selector(markAllAsRead))
    }()

    /// Haptic Feedback!
    ///
    private let hapticGenerator = UINotificationFeedbackGenerator()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Notes in sync.
    ///
    private lazy var resultsController: ResultsController<StorageNote> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageNote.timestamp, ascending: false)

        return ResultsController<StorageNote>(storageManager: storageManager,
                                              sectionNameKeyPath: "normalizedAgeAsString",
                                              matching: self.filterPredicate(),
                                              sortedBy: [descriptor])
    }()

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

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    /// String Formatter: Given a NoteBlock, this tool will return an AttributedString.
    ///
    private let formatter = StringFormatter()

    /// UI Active State
    ///
    private var state: State = .results {
        didSet {
            willEnter(state: state)

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

    /// The last seen time for notifications
    ///
    private var lastSeenTime: String? {
        get {
            return UserDefaults.standard[.notificationsLastSeenTime]
        }
        set {
            return UserDefaults.standard[.notificationsLastSeenTime] = newValue
        }
    }

    /// The number of times the "Mark all as read" button was tapped
    ///
    private var markAsReadCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: UserDefaults.Key.notificationsMarkAsReadCount.rawValue)
        }
        set {
            return UserDefaults.standard[.notificationsMarkAsReadCount] = newValue
        }
    }

    // MARK: - View Lifecycle

    deinit {
        stopListeningToNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // This 👇 should be called in init so the tab is correctly localized when the app launches
        configureTabBarItem()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = StyleManager.tableViewBackgroundColor

        refreshTitle()
        refreshResultsPredicate()
        configureNavigationItem()
        configureNavigationBarButtons()
        configureTableView()
        configureTableViewCells()
        configureResultsController()

        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resetApplicationBadge()
        transitionToResultsUpdatedState()
        synchronizeNotifications() {
            // FIXME: This is being disabled temporarily because of a race condition caused with WPiOS.
            // We should consider updating and re-enabling this logic (when updates happen on the server) at a later time.
            // See this issue for more deets: https://github.com/woocommerce/woocommerce-ios/issues/469
            //
            //self?.updateLastSeenTime()
        }

        if AppRatingManager.shared.shouldPromptForAppReview(section: Constants.section) {
            displayRatingPrompt()
        }
    }
}


// MARK: - User Interface Initialization
//
private extension NotificationsViewController {

    /// Setup: TabBar
    ///
    func configureTabBarItem() {
        tabBarItem.title = NSLocalizedString("Reviews", comment: "Title of the Reviews tab — plural form of Review")
        tabBarItem.image = .commentImage
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
        leftBarButton.tintColor = .white
        leftBarButton.accessibilityTraits = .button
        leftBarButton.accessibilityLabel = NSLocalizedString("Mark All as Read", comment: "Accessibility label for the Mark All Notifications as Read Button")
        leftBarButton.accessibilityHint = NSLocalizedString("Marks Every Notification as Read",
                                                            comment: "VoiceOver accessibility hint for the Mark All Notifications as Read Action")
        navigationItem.leftBarButtonItem = leftBarButton
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.refreshControl = refreshControl
    }

    /// Setup: ResultsController
    ///
    func configureResultsController() {
        resultsController.startForwardingEvents(to: tableView)
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

    func refreshTitle() {
        transitionToResultsUpdatedState()
        navigationItem.title = NSLocalizedString(
            "Reviews",
            comment: "Title that appears on top of the main Reviews screen (plural form of the word Review)."
        )
    }
}


// MARK: - Actions
//
private extension NotificationsViewController {

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.notificationsListPulledToRefresh)
        synchronizeNotifications {
            sender.endRefreshing()
        }
    }

    @IBAction func markAllAsRead() {
        ServiceLocator.analytics.track(.notificationsListReadAllTapped)
        if unreadNotes.isEmpty {
            DDLogVerbose("# Every single notification is already marked as Read!")
            return
        }

        markAsRead(notes: unreadNotes)
    }
}


// MARK: - Yosemite Wrappers
//
private extension NotificationsViewController {

    /// Nukes the BadgeCount
    ///
    func resetApplicationBadge() {
        ServiceLocator.pushNotesManager.resetBadgeCount()
    }

    /// Update the last seen time for notifications
    ///
    func updateLastSeenTime() {
        guard let firstNote = resultsController.fetchedObjects.first else {
            return
        }
        guard firstNote.timestamp != lastSeenTime else {
            return
        }

        let timestamp = firstNote.timestamp
        let action = NotificationAction.updateLastSeen(timestamp: timestamp) { [weak self] (error) in
            if let error = error {
                DDLogError("⛔️ Error marking notifications as seen: \(error)")
            } else {
                self?.lastSeenTime = timestamp
            }
        }

        ServiceLocator.stores.dispatch(action)
    }

    /// Marks a specific Notification as read.
    ///
    func markAsReadIfNeeded(note: Note) {
        guard note.read == false else {
            return
        }

        let action = NotificationAction.updateReadStatus(noteId: note.noteId, read: true) { (error) in
            if let error = error {
                DDLogError("⛔️ Error marking single notification as read: \(error)")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Marks the specified collection of Notifications as Read.
    ///
    func markAsRead(notes: [Note]) {
        let identifiers = notes.map { $0.noteId }
        let action = NotificationAction.updateMultipleReadStatus(noteIds: identifiers, read: true) { [weak self] error in
            if let error = error {
                DDLogError("⛔️ Error marking multiple notifications as read: \(error)")
                self?.hapticGenerator.notificationOccurred(.error)
            } else {
                self?.hapticGenerator.notificationOccurred(.success)
                self?.displayMarkAllAsReadNoticeIfNeeded()
            }
            self?.updateMarkAllReadButtonState()
        }

        ServiceLocator.stores.dispatch(action)
    }

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    func synchronizeNotifications(onCompletion: (() -> Void)? = nil) {
        let action = NotificationAction.synchronizeNotifications { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing notifications: \(error)")
            } else {
                ServiceLocator.analytics.track(.notificationListLoaded)
            }

            self.refreshResultsPredicate()
            self.transitionToResultsUpdatedState()
            onCompletion?()
        }

        transitionToSyncingState()
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - App Store Review Prompt
//
private extension NotificationsViewController {
    func displayRatingPrompt() {
        defer {
            if let wooEvent = WooAnalyticsStat.valueOf(stat: .appReviewsRatedApp) {
                ServiceLocator.analytics.track(wooEvent)
            }
        }

        // Show the app store ratings alert
        // Note: Optimistically assuming our prompting succeeds since we try to stay
        // in line and not prompt more than two times a year
        AppRatingManager.shared.ratedCurrentVersion()
        SKStoreReviewController.requestReview()
    }
}

// MARK: - ResultsController
//
private extension NotificationsViewController {

    /// Refreshes the Results Controller Predicate, and ensures the UI is in Sync.
    ///
    func reloadResultsController() {
        refreshResultsPredicate()

        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
        transitionToSyncingState()
    }

    func refreshResultsPredicate() {
        resultsController.predicate = filterPredicate()
    }

    func filterPredicate() -> NSPredicate {
        let notDeletedPredicate = NSPredicate(format: "deleteInProgress == NO")
        let sitePredicate = NSPredicate(format: "siteID == %lld", ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
        let typeReviewPredicate =  NSPredicate(format: "subtype == %@", Note.Subkind.storeReview.rawValue)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [typeReviewPredicate,
                                                                   sitePredicate,
                                                                   notDeletedPredicate])
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

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? Settings.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let note = resultsController.object(at: indexPath)
        presentDetails(for: note)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid yout yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height
    }
}


// MARK: - Public Methods
//
extension NotificationsViewController {

    /// Presents the Details for the Notification with the specified Identifier.
    ///
    /// NOTE: This method will not perform any kind of RPC. It's effectively a NO-OP whenever the target note hasn't been
    /// already retrieved.
    ///
    func presentDetails(for noteId: Int) {
        let notificationMaybe = resultsController.fetchedObjects.first { $0.noteId == noteId }
        guard let notification = notificationMaybe else {
            return
        }

        presentDetails(for: notification)
    }

    /// Presents the Details for a given Note Instance: Either NotificationDetails, or OrderDetails, depending on the
    /// Notification's Kind.
    ///
    func presentDetails(for note: Note) {
        switch note.kind {
        case .storeOrder:
            presentOrderDetails(for: note)
        default:
            presentNotificationDetails(for: note)
        }

        ServiceLocator.analytics.track(.notificationOpened, withProperties: [ "type": note.kind.rawValue,
                                                                         "already_read": note.read ])

        markAsReadIfNeeded(note: note)
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
        cell.noticonColor = note.noticonTintColor
        cell.attributedSubject = renderSubject(note: note)
        cell.attributedSnippet = renderSnippet(note: note)
        cell.starRating = note.starRating
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
    func displayEmptyUnfilteredOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = .waitingForCustomersImage
        overlayView.messageText = NSLocalizedString("No Reviews Yet!", comment: "Empty Reviews List Message")
        overlayView.actionText = NSLocalizedString("Share your Store", comment: "Action: Opens the Store in a browser")
        overlayView.onAction = { [weak self] in
            guard let `self` = self else {
                return
            }
            guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
                return
            }
            guard let url = URL(string: site.url) else {
                return
            }

            ServiceLocator.analytics.track(.notificationShareStoreButtonTapped)
            SharingHelper.shareURL(url: url, title: site.name, from: overlayView.actionButtonView, in: self)
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
}


// MARK: - Notifications
//
private extension NotificationsViewController {

    /// Setup: Notification Hooks
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultSiteWasUpdated), name: .StoresManagerDidUpdateDefaultSite, object: nil)
        nc.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
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

    /// Application became Active Again (while the Notes Tab was onscreen)
    ///
    @objc func applicationDidBecomeActive() {
        guard isViewLoaded == true && view.window != nil else {
            return
        }

        resetApplicationBadge()
    }
}


// MARK: - Finite State Machine Management
//
private extension NotificationsViewController {

    /// Runs prior to the FSM entering a new state.
    ///
    /// Note: Just because this func runs does not guarantee `didEnter()` or `didLeave()` will run as well.
    ///
    func willEnter(state: State) {
        updateNavBarButtonsState()
    }

    /// Runs whenever the FSM enters a State.
    ///
    func didEnter(state: State) {
        switch state {
        case .emptyUnfiltered:
            if isEmpty == true {
                displayEmptyUnfilteredOverlay()
            }
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
        case .emptyUnfiltered:
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

    /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
    /// Transitions to `.results` / `.emptyFiltered` / `.emptyUnfiltered` accordingly.
    ///
    func transitionToResultsUpdatedState() {
        if isEmpty == false {
            state = .results
            return
        }

        state = .emptyUnfiltered
    }
}


// MARK: - Private Helpers
//
private extension NotificationsViewController {

    /// Enables/disables the navbar buttons if needed
    ///
    /// - Parameter filterEnabled: If true, the filter navbar buttons is enabled; if false, it's disabled
    ///
    func updateNavBarButtonsState() {
        updateMarkAllReadButtonState()
    }

    func updateMarkAllReadButtonState() {
        leftBarButton.isEnabled = !unreadNotes.isEmpty
    }

    /// Displays the `Mark all as read` Notice if the number of times it was previously displayed is lower than the
    /// `Settings.markAllAsReadNoticeMaxViews` value.
    ///
    func displayMarkAllAsReadNoticeIfNeeded() {
        guard markAsReadCount < Settings.markAllAsReadNoticeMaxViews else {
            return
        }

        markAsReadCount += 1
        let message = NSLocalizedString("All notifications marked as read", comment: "Mark all notifications as read notice")
        let notice = Notice(title: message, feedbackType: .success)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Nested Types
//
private extension NotificationsViewController {

    enum NoteTypeFilter: String {
        case all
        case orders = "store_order"
        case reviews = "store_review"

        /// Returns a collection of all of the known Note Types
        ///
        static var knownTypes: [NoteTypeFilter] {
            return [.all, .orders, .reviews]
        }

        var description: String {
            switch self {
            case .all:
                return NSLocalizedString("All",
                                         comment: "Name of the All filter on the Notifications screen - it means all notifications will be displayed."
                )
            case .orders:
                return NSLocalizedString("Orders",
                                         comment: "Name of the Orders filter on the Notifications screen - it means only order notifications will be displayed. Plural form of the word Order."
                )
            case .reviews:
                return NSLocalizedString("Reviews",
                                         comment: "Name of the Reviews filter on the Notifications screen - it means only review notifications will be displayed. Plural form of the word Review."
                )
            }
        }
    }

    enum Settings {
        static let estimatedRowHeight             = CGFloat(88)
        static let placeholderRowsPerSection      = [3]
        static let markAllAsReadNoticeMaxViews    = 2
    }

    enum State {
        case emptyUnfiltered
        case results
        case syncing
    }

    struct Constants {
        static let section = "notifications"
    }
}
