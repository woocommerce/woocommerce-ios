import UIKit
import SafariServices.SFSafariViewController


// MARK: - ReviewsViewController
//
final class ReviewsViewController: UIViewController {

    typealias ViewModel = ReviewsViewModelOutput & ReviewsViewModelActionsHandler

    /// Main TableView.
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// Mark all as read nav bar button
    ///
    private lazy var rightBarButton: UIBarButtonItem = {
        let item = UIBarButtonItem(image: .ellipsisImage,
                                   style: .plain,
                                   target: self,
                                   action: #selector(presentMoreActions))
        item.accessibilityIdentifier = "reviews-open-menu-button"
        item.accessibilityTraits = .button
        item.accessibilityLabel = Localization.MenuButton.accessibilityLabel
        item.accessibilityHint = Localization.MenuButton.accessibilityHint
        return item
    }()

    private let viewModel: ViewModel

    /// Haptic Feedback!
    ///
    private let hapticGenerator = UINotificationFeedbackGenerator()

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

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
        return viewModel.isEmpty
    }

    /// The view shown if the list is empty.
    ///
    private lazy var emptyStateViewController = EmptyStateViewController(style: .list)

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

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    /// Top banner that shows an error if there is a problem loading reviews data
    ///
    private lazy var topBannerView: TopBannerView = {
        ErrorTopBannerFactory.createTopBanner(isExpanded: false,
                                              expandedStateChangeHandler: { [weak self] in
                                                self?.tableView.updateHeaderHeight()
                                              },
                                              onTroubleshootButtonPressed: { [weak self] in
                                                let safariViewController = SFSafariViewController(url: WooConstants.URLs.troubleshootErrorLoadingData.asURL())
                                                self?.present(safariViewController, animated: true, completion: nil)
                                              },
                                              onContactSupportButtonPressed: { [weak self] in
                                                guard let self = self else { return }
                                                ZendeskProvider.shared.showNewRequestIfPossible(from: self, with: nil)
                                              })
    }()

    // MARK: - Initializers
    //
    convenience init(siteID: Int64) {
        self.init(viewModel: ReviewsViewModel(siteID: siteID,
                                              data: DefaultReviewsDataSource(siteID: siteID)))
    }

    init(viewModel: ViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        // This 👇 should be called in init so the tab is correctly localized when the app launches
        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .listBackground

        refreshTitle()

        configureSyncingCoordinator()
        configureTableView()
        configureTableViewCells()
        configureResultsController()

        startListeningToNotifications()
        syncingCoordinator.resynchronize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resetApplicationBadge()

        if state == .emptyUnfiltered {
            syncingCoordinator.resynchronize()
        }

        if viewModel.shouldPromptForAppReview {
            displayRatingPrompt()
        }

        // Fix any incomplete animation of the refresh control
        // when switching tabs mid-animation
        refreshControl.resetAnimation(in: tableView) { [unowned self] in
            // ghost animation is also removed after switching tabs
            // show make sure it's displayed again
            self.removePlaceholderReviews()
            self.displayPlaceholderReviews()
        }
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }
}


// MARK: - User Interface Initialization
//
private extension ReviewsViewController {

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Setup: TabBar
    ///
    func configureTabBarItem() {
        tabBarItem.title = Localization.tabBarItemTitle
        tabBarItem.image = .starOutlineImage()
        tabBarItem.accessibilityIdentifier = "tab-bar-reviews-item"
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.dataSource = viewModel.dataSource
        tableView.tableFooterView = footerSpinnerView
        tableView.sectionFooterHeight = .leastNonzeroMagnitude

        // Adds the refresh control to table view manually so that the refresh control always appears below the navigation bar title in
        // large or normal size to be consistent with Dashboard and Orders tab with large titles workaround.
        // If we do `tableView.refreshControl = refreshControl`, the refresh control appears in the navigation bar when large title is shown.
        tableView.addSubview(refreshControl)

        // We decorate the delegate informally, because we want to intercept
        // didSelectItem:at: but delegate the rest of the implementation of
        // UITableViewDelegate to the implementation of UITableViewDelegate
        // provided by the view model. It could be argued that we are just cheating.
        tableView.delegate = self

        tableView.accessibilityIdentifier = "reviews-table"
    }

    /// Setup: ResultsController
    ///
    func configureResultsController() {
        viewModel.configureResultsController(tableView: tableView)
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells() {
        viewModel.configureTableViewCells(tableView: tableView)
    }

    func refreshTitle() {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.hubMenu) {
            title = Localization.title
        } else {
            navigationItem.title = Localization.title
        }
    }
}


// MARK: - Actions
//
private extension ReviewsViewController {

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.reviewsListPulledToRefresh)
        syncingCoordinator.resynchronize() {
            sender.endRefreshing()
        }
    }

    /// Presents an action sheet on tapping the menu right bar button item.
    ///
    @IBAction func presentMoreActions() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text
        actionSheet.popoverPresentationController?.barButtonItem = rightBarButton

        actionSheet.addCancelActionWithTitle(Localization.ActionSheet.cancelAction)
        actionSheet.addDefaultActionWithTitle(Localization.ActionSheet.markAsReadAction) { [weak self] _ in
            self?.presentMarkAllAsReadConfirmationAlert()
        }

        present(actionSheet, animated: true)
    }

    @IBAction func markAllAsRead() {
        ServiceLocator.analytics.track(.reviewsListReadAllTapped)

        viewModel.markAllAsRead { [weak self] error in
            let tracks = ServiceLocator.analytics
            tracks.track(.reviewsMarkAllRead)

            guard let self = self else {
                return
            }

            if let error = error {
                DDLogError("⛔️ Error marking multiple notifications as read: \(error)")
                self.hapticGenerator.notificationOccurred(.error)

                tracks.track(.reviewsMarkAllReadFailed, withError: error)
            } else {
                self.hapticGenerator.notificationOccurred(.success)
                self.displayMarkAllAsReadNoticeIfNeeded()

                tracks.track(.reviewsMarkAllReadSuccess)
            }

            self.updateRightBarButtonItem()
            self.tableView.reloadData()
        }
    }
}


// MARK: - UITableViewDelegate
extension ReviewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.delegate.tableView?(tableView, heightForHeaderInSection: section) ?? 0
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.delegate.tableView?(tableView, estimatedHeightForRowAt: indexPath) ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.delegate.tableView?(tableView, heightForRowAt: indexPath) ?? 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.delegate.didSelectItem(at: indexPath, in: self)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.delegate.tableView(tableView, willDisplay: cell, forRowAt: indexPath, with: syncingCoordinator)
    }
}

// MARK: - Yosemite Wrappers
//
private extension ReviewsViewController {

    /// Nukes the BadgeCount
    ///
    func resetApplicationBadge() {
        ServiceLocator.pushNotesManager.resetBadgeCount(type: .comment)
    }
}

// MARK: - Placeholders
//
private extension ReviewsViewController {

    /// Renders Placeholder Reviews.
    ///
    func displayPlaceholderReviews() {
        viewModel.displayPlaceholderReviews(tableView: tableView)
    }

    /// Removes Placeholder Reviews.
    ///
    func removePlaceholderReviews() {
        viewModel.removePlaceholderReviews(tableView: tableView)
    }

    /// Displays the EmptyStateViewController.
    ///
    func displayEmptyViewController() {
        let childController = emptyStateViewController
        let emptyStateConfig = EmptyStateViewController.Config.withLink(message: NSAttributedString(string: Localization.EmptyState.message),
                                                                        image: .emptyReviewsImage,
                                                                        details: Localization.EmptyState.detail,
                                                                        linkTitle: Localization.EmptyState.action,
                                                                        linkURL: WooConstants.URLs.productReviewInfo.asURL())

        // Abort if we are already displaying this childController
        guard childController.parent == nil,
              let childView = childController.view else {
            return
        }

        childController.configure(emptyStateConfig)

        // Show Error Loading Data banner if the empty state is caused by a sync error
        if viewModel.hasErrorLoadingData {
            childController.showTopBannerView()
        } else {
            childController.hideTopBannerView()
        }

        childView.translatesAutoresizingMaskIntoConstraints = false

        addChild(childController)
        view.addSubview(childView)
        tableView.pinSubviewToAllEdges(childView)
        childController.didMove(toParent: self)
    }

    func removeEmptyViewController() {
        let childController = emptyStateViewController

        guard childController.parent == self,
            let childView = childController.view else {
            return
        }

        childController.willMove(toParent: nil)
        childView.removeFromSuperview()
        childController.removeFromParent()
    }
}


// MARK: - Notifications
//
private extension ReviewsViewController {

    /// Setup: Notification Hooks
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
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
private extension ReviewsViewController {

    /// Runs prior to the FSM entering a new state.
    ///
    /// Note: Just because this func runs does not guarantee `didEnter()` or `didLeave()` will run as well.
    ///
    func willEnter(state: State) {
        updateRightBarButtonItem()
    }

    /// Runs whenever the FSM enters a State.
    ///
    func didEnter(state: State) {
        switch state {
        case .emptyUnfiltered:
            if isEmpty == true {
                displayEmptyViewController()
            }
        case .results:
            break
        case .placeholder:
            displayPlaceholderReviews()
        case .syncing(let pageNumber):
            if pageNumber != SyncingCoordinator.Defaults.pageFirstIndex {
                ensureFooterSpinnerIsStarted()
            }
        }
    }

    /// Runs whenever the FSM leaves a State.
    ///
    func didLeave(state: State) {
        switch state {
        case .emptyUnfiltered:
            removeEmptyViewController()
        case .results:
            break
        case .placeholder:
            removePlaceholderReviews()
        case .syncing:
            ensureFooterSpinnerIsStopped()
            removePlaceholderReviews()
        }
    }

    /// Should be called before Sync'ing Starts: Transitions to .results / .syncing
    ///
    func transitionToSyncingState(pageNumber: Int) {
        state = isEmpty ? .placeholder : .syncing(pageNumber: pageNumber)
        // Remove banner for error loading data during sync
        hideTopBannerView()
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
private extension ReviewsViewController {

    /// Show the rightBarButtonItem only if there are unread reviews available.
    ///
    func updateRightBarButtonItem() {
        navigationItem.rightBarButtonItem = viewModel.hasUnreadNotifications ? rightBarButton : nil
    }

    /// Displays the `Mark all as read` Notice if the number of times it was previously displayed is lower than the
    /// `Settings.markAllAsReadNoticeMaxViews` value.
    ///
    func displayMarkAllAsReadNoticeIfNeeded() {
        guard markAsReadCount < Settings.markAllAsReadNoticeMaxViews else {
            return
        }

        markAsReadCount += 1
        let notice = Notice(title: Localization.Notice.allReviewsMarkedAsRead, feedbackType: .success)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Presents an alert which asks the user for confirmation
    /// before marking all reviews as read.
    ///
    func presentMarkAllAsReadConfirmationAlert() {
        let alertController = UIAlertController(title: Localization.MarkAllAsReadAlert.title,
                                                message: Localization.MarkAllAsReadAlert.message,
                                                preferredStyle: .alert)
        alertController.view.tintColor = .text

        alertController.addActionWithTitle(Localization.MarkAllAsReadAlert.cancelButtonTitle, style: .destructive)
        alertController.addDefaultActionWithTitle(Localization.MarkAllAsReadAlert.markAllButtonTitle) { [weak self] _ in
            self?.markAllAsRead()
        }

        present(alertController, animated: true)
    }
}


// MARK: - Sync'ing Helpers
//
extension ReviewsViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Orders for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)? = nil) {
        transitionToSyncingState(pageNumber: pageNumber)
        viewModel.synchronizeReviews(pageNumber: pageNumber, pageSize: pageSize) { [weak self] in
            guard let self = self else { return }
            self.transitionToResultsUpdatedState()
            if self.viewModel.hasErrorLoadingData {
                self.showTopBannerView()
            }
            onCompletion?(true)
        }
    }

    /// Display the error banner in the table view header
    ///
    private func showTopBannerView() {
        // Configure header container view
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: 0))
        headerContainer.addSubview(topBannerView)
        headerContainer.pinSubviewToSafeArea(topBannerView)

        tableView.tableHeaderView = headerContainer
        tableView.updateHeaderHeight()
    }

    /// Hide the error banner from the table view header
    ///
    private func hideTopBannerView() {
        topBannerView.removeFromSuperview()
        tableView.tableHeaderView = nil
    }
}

// MARK: - Spinner Helpers
//
extension ReviewsViewController {

    /// Starts the Footer Spinner animation, whenever `mustStartFooterSpinner` returns *true*.
    ///
    private func ensureFooterSpinnerIsStarted() {
        guard mustStartFooterSpinner() else {
            return
        }

        footerSpinnerView.startAnimating()
    }

    /// Whenever we're sync'ing an Orders Page that's beyond what we're currently displaying, this method will return *true*.
    ///
    private func mustStartFooterSpinner() -> Bool {
        guard let highestPageBeingSynced = syncingCoordinator.highestPageBeingSynced else {
            return false
        }

        return viewModel.containsMorePages(highestPageBeingSynced * SyncingCoordinator.Defaults.pageSize)
    }

    /// Stops animating the Footer Spinner.
    ///
    private func ensureFooterSpinnerIsStopped() {
        footerSpinnerView.stopAnimating()
    }
}


// MARK: - Nested Types
//
private extension ReviewsViewController {

    enum Settings {
        static let estimatedRowHeight             = CGFloat(88)
        static let placeholderRowsPerSection      = [3]
        static let markAllAsReadNoticeMaxViews    = 2
    }

    enum State: Equatable {
        case placeholder
        case emptyUnfiltered
        case results
        case syncing(pageNumber: Int)
    }
}

// MARK: - Localization
//
private extension ReviewsViewController {
    enum Localization {
        static let title = NSLocalizedString("Reviews",
                                             comment: "Title that appears on top of the main Reviews screen (plural form of the word Review).")

        static let tabBarItemTitle = NSLocalizedString("Reviews",
                                                       comment: "Title of the Reviews tab — plural form of Review")

        enum MenuButton {
            static let accessibilityLabel = NSLocalizedString("Open menu",
                                                        comment: "Accessibility label for the Menu button")
            static let accessibilityHint = NSLocalizedString("Menu button which opens an action sheet with option to mark all reviews as read.",
                                                       comment: "VoiceOver accessibility hint for the Menu button action")
        }

        enum ActionSheet {
            static let markAsReadAction = NSLocalizedString("Mark all reviews as read",
                                                            comment: "Option to mark all reviews as read from the action sheet in Reviews screen.")

            static let cancelAction = NSLocalizedString("Cancel",
                                                        comment: "Cancel the more menu action sheet in Reviews screen.")
        }

        enum MarkAllAsReadAlert {
            static let title = NSLocalizedString("Mark all as read",
                                                 comment: "Title of Alert which asks user for confirmation before marking all reviews as read.")

            static let message = NSLocalizedString("Are you sure you want to mark all reviews as read?",
                                                   comment: "Alert message to confirm a user meant to mark all reviews as read.")

            static let cancelButtonTitle = NSLocalizedString("Cancel",
                                                             comment: "Alert button title - dismisses alert, which cancels marking all as read attempt.")

            static let markAllButtonTitle = NSLocalizedString("Mark all",
                                                              comment: "Alert button title - confirms and marks all reviews as read")
        }

        enum Notice {
            static let allReviewsMarkedAsRead = NSLocalizedString("All reviews marked as read",
                                                                  comment: "Mark all reviews as read notice")
        }

        enum EmptyState {
            static let message = NSLocalizedString("Get your first reviews",
                                                             comment: "Message shown in the Reviews tab if the list is empty")
            static let detail = NSLocalizedString("Capture high-quality product reviews for your store.",
                                                            comment: "Detailed message shown in the Reviews tab if the list is empty")
            static let action = NSLocalizedString("Learn more",
                                                            comment: "Title of button shown in the Reviews tab if the list is empty")
        }
    }
}
