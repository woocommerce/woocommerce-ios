import UIKit
import Gridicons
import Yosemite
import WordPressUI
import SafariServices
import StoreKit


/// OrdersViewController: Displays the list of Orders associated to the active Store / Account.
///
class OrdersViewController: UIViewController {

    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// Ghostable TableView.
    ///
    private(set) var ghostableTableView = UITableView()

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = {
        return FooterSpinnerView(tableViewStyle: tableView.style)
    }()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Orders in sync.
    ///
    private lazy var resultsController: ResultsController<StorageOrder> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)

        return ResultsController<StorageOrder>(storageManager: storageManager, sectionNameKeyPath: "normalizedAgeAsString", sortedBy: [descriptor])
    }()

    /// ResultsController: Handles all things order status
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// OrderStatus that must be matched by retrieved orders.
    ///
    var statusFilter: OrderStatus? {
        didSet {
            guard isViewLoaded else {
                return
            }

            guard oldValue != statusFilter else {
                return
            }

            didChangeFilter(newFilter: statusFilter)
        }
    }

    /// The current list of order statuses for the default site
    ///
    private var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
    }

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        return resultsController.isEmpty
    }

    /// Indicates if there's a filter being applied.
    ///
    private var isFiltered: Bool {
        return statusFilter != nil
    }

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

    /// Called when `self` is about to fetch Orders from the API.
    ///
    var willSynchronizeOrders: (() -> ())?

    // MARK: - View Lifecycle

    /// Create an instance of `Self` from its corresponding storyboard.
    ///
    static func instantiatedViewControllerFromStoryboard() -> Self? {
        let storyboard = UIStoryboard.orders
        let identifier = "OrdersViewController"
        return storyboard.instantiateViewController(withIdentifier: identifier) as? Self
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshTitle()
        refreshResultsPredicate()
        refreshStatusPredicate()
        registerTableViewCells()

        configureSyncingCoordinator()
        configureNavigation()
        configureTableView()
        configureGhostableTableView()
        configureResultsControllers()

        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncingCoordinator.synchronizeFirstPage()
        if AppRatingManager.shared.shouldPromptForAppReview() {
            displayRatingPrompt()
        }
    }
}


// MARK: - User Interface Initialization
//
private extension OrdersViewController {

    /// Setup: Title
    ///
    func refreshTitle() {
        guard let filterName = statusFilter?.name else {
            navigationItem.title = NSLocalizedString(
                "Orders",
                comment: "Title that appears on top of the Order List screen when there is no filter applied to the list (plural form of the word Order)."
            )
            return
        }

        let title = String.localizedStringWithFormat(
            NSLocalizedString(
                "Orders: %@",
                comment: "Title that appears on top of the Order List screen when a filter is applied. It reads: Orders: {name of filter}"
            ),
            filterName
        )
        navigationItem.title = title
    }

    /// Setup: Order filtering
    ///
    func refreshResultsPredicate() {
        resultsController.predicate = {
            let excludeSearchCache = NSPredicate(format: "exclusiveForSearch = false")
            let excludeNonMatchingStatus = statusFilter.map { NSPredicate(format: "statusKey = %@", $0.slug) }

            var predicates = [ excludeSearchCache, excludeNonMatchingStatus ].compactMap { $0 }
            if let tomorrow = Date.tomorrow() {
                let dateSubPredicate = NSPredicate(format: "dateCreated < %@", tomorrow as NSDate)
                predicates.append(dateSubPredicate)
            }

            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }()

        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()
    }

    /// Setup: Order status predicate
    ///
    func refreshStatusPredicate() {
        // Bugfix for https://github.com/woocommerce/woocommerce-ios/issues/751.
        // Because we are listening for default account changes,
        // this will also fire upon logging out, when the account
        // is set to nil. So let's protect against multi-threaded
        // access attempts if the account is indeed nil.
        guard ServiceLocator.stores.isAuthenticated,
            ServiceLocator.stores.needsDefaultStore == false else {
                return
        }

        statusResultsController.predicate = NSPredicate(format: "siteID == %lld", ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
    }

    /// Setup: Navigation Item
    ///
    func configureNavigation() {
        navigationItem.leftBarButtonItem = {
            let button = UIBarButtonItem(image: .searchImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(displaySearchOrders))
            button.accessibilityTraits = .button
            button.accessibilityLabel = NSLocalizedString("Search orders", comment: "Search Orders")
            button.accessibilityHint = NSLocalizedString(
                "Retrieves a list of orders that contain a given keyword.",
                comment: "VoiceOver accessibility hint, informing the user the button can be used to search orders."
            )
            button.accessibilityIdentifier = "order-search-button"

            return button
        }()

        // Don't show the Order title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Setup: Results Controller
    ///
    func configureResultsControllers() {
        // Orders FRC
        resultsController.startForwardingEvents(to: tableView)
        try? resultsController.performFetch()

        // Order status FRC
        try? statusResultsController.performFetch()
    }

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = footerSpinnerView
    }

    /// Setup: Ghostable TableView
    ///
    func configureGhostableTableView() {
        view.addSubview(ghostableTableView)
        ghostableTableView.isHidden = true

        ghostableTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ghostableTableView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            ghostableTableView.heightAnchor.constraint(equalTo: tableView.heightAnchor),
            ghostableTableView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            ghostableTableView.topAnchor.constraint(equalTo: tableView.topAnchor)
        ])

        view.backgroundColor = .listBackground
        ghostableTableView.backgroundColor = .listBackground
        ghostableTableView.isScrollEnabled = false
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [ OrderTableViewCell.self ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
            ghostableTableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}


// MARK: - Notifications
//
extension OrdersViewController {

    /// Wires all of the Notification Hooks
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultAccountWasUpdated), name: .defaultAccountWasUpdated, object: nil)
        nc.addObserver(self, selector: #selector(stopListeningToNotifications), name: .logOutEventReceived, object: nil)
    }

    /// Stops listening to all related Notifications
    ///
    @objc func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    /// Runs whenever the default Account is updated.
    ///
    @objc func defaultAccountWasUpdated() {
        statusFilter = nil
        refreshStatusPredicate()
        syncingCoordinator.resetInternalState()
    }
}


// MARK: - Push Notification Handling
//
extension OrdersViewController {
    /// Presents the Details for the Notification with the specified Identifier.
    ///
    func presentDetails(for note: Note) {
        guard let orderID = note.meta.identifier(forKey: .order), let siteID = note.meta.identifier(forKey: .site) else {
            DDLogError("## Notification with [\(note.noteID)] lacks its OrderID!")
            return
        }

        let loaderViewController = OrderLoaderViewController(note: note, orderID: Int64(orderID), siteID: Int64(siteID))
        navigationController?.pushViewController(loaderViewController, animated: true)
    }
}


// MARK: - Actions
//
extension OrdersViewController {

    @IBAction func displaySearchOrders() {
        guard let storeID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        ServiceLocator.analytics.track(.ordersListSearchTapped)

        let searchViewController = SearchViewController<OrderTableViewCell, OrderSearchUICommand>(storeID: storeID,
                                                                                                  command: OrderSearchUICommand(),
                                                                                                  cellType: OrderTableViewCell.self)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.ordersListPulledToRefresh)
        willSynchronizeOrders?()
        syncingCoordinator.synchronizeFirstPage {
            sender.endRefreshing()
        }
    }
}


// MARK: - Filters
//
private extension OrdersViewController {

    func didChangeFilter(newFilter: OrderStatus?) {
        ServiceLocator.analytics.track(.filterOrdersOptionSelected,
                                  withProperties: ["status": newFilter?.slug ?? String()])
        ServiceLocator.analytics.track(.ordersListFilterOrSearch,
                                  withProperties: ["filter": newFilter?.slug ?? String(),
                                                   "search": ""])
        // Display the Filter in the Title
        refreshTitle()

        // Filter right away the cached orders
        refreshResultsPredicate()

        // Drop Cache (If Needed) + Re-Sync First Page
        ensureStoredOrdersAreReset { [weak self] in
            self?.syncingCoordinator.resynchronize()
        }
    }

    /// Nukes all of the Stored Orders:
    /// We're dropping the entire Orders Cache whenever a filter was just removed. This is performed to avoid
    /// "interleaved Sync'ed Objects", which results in an awful UX while scrolling down
    ///
    func ensureStoredOrdersAreReset(onCompletion: @escaping () -> Void) {
        guard isFiltered == false else {
            onCompletion()
            return
        }

        let action = OrderAction.resetStoredOrders(onCompletion: onCompletion)
        ServiceLocator.stores.dispatch(action)
    }
}


// MARK: - Sync'ing Helpers
//
extension OrdersViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Orders for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)? = nil) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            onCompletion?(false)
            return
        }

        transitionToSyncingState()

        let action = OrderAction.synchronizeOrders(siteID: siteID,
                                                   statusKey: statusFilter?.slug,
                                                   pageNumber: pageNumber,
                                                   pageSize: pageSize) { [weak self] error in
            guard let self = self else {
                return
            }

            if let error = error {
                DDLogError("⛔️ Error synchronizing orders: \(error)")
                self.displaySyncingErrorNotice(pageNumber: pageNumber, pageSize: pageSize)
            } else {
                ServiceLocator.analytics.track(.ordersListLoaded, withProperties: ["status": self.statusFilter?.slug ?? String()])
            }

            self.transitionToResultsUpdatedState()
            onCompletion?(error == nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}


// MARK: - Spinner Helpers
//
extension OrdersViewController {

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

        return highestPageBeingSynced * SyncingCoordinator.Defaults.pageSize > resultsController.numberOfObjects
    }

    /// Stops animating the Footer Spinner.
    ///
    private func ensureFooterSpinnerIsStopped() {
        footerSpinnerView.stopAnimating()
    }
}


// MARK: - Placeholders & Ghostable Table
//
private extension OrdersViewController {

    /// Renders the Placeholder Orders
    ///
    func displayPlaceholderOrders() {
        let options = GhostOptions(reuseIdentifier: OrderTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)

        // If the ghostable table view gets stuck for any reason,
        // let's reset the state before using it again
        ghostableTableView.removeGhostContent()
        ghostableTableView.displayGhostContent(options: options,
                                               style: .wooDefaultGhostStyle)
        ghostableTableView.startGhostAnimation()
        ghostableTableView.isHidden = false
    }

    /// Removes the Placeholder Orders (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderOrders() {
        ghostableTableView.isHidden = true
        ghostableTableView.stopGhostAnimation()
        ghostableTableView.removeGhostContent()
        tableView.reloadData()
    }

    /// Displays the Error Notice.
    ///
    func displaySyncingErrorNotice(pageNumber: Int, pageSize: Int) {
        let message = NSLocalizedString("Unable to refresh list", comment: "Refresh Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.willSynchronizeOrders?()
            self?.sync(pageNumber: pageNumber, pageSize: pageSize)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the Empty State Overlay.
    ///
    func displayEmptyUnfilteredOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = .waitingForCustomersImage
        overlayView.messageText = NSLocalizedString("Waiting for Customers", comment: "Orders List (Empty State / No Filters)")
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

            ServiceLocator.analytics.track(.orderShareStoreButtonTapped)
            SharingHelper.shareURL(url: url, title: site.name, from: overlayView.actionButtonView, in: self)
        }

        overlayView.attach(to: view)
    }

    /// Displays the Empty State (with filters applied!) Overlay.
    ///
    func displayEmptyFilteredOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = .waitingForCustomersImage
        overlayView.messageText = NSLocalizedString("No results for the selected criteria", comment: "Orders List (Empty State + Filters)")
        overlayView.actionText = NSLocalizedString("Remove Filters", comment: "Action: Opens the Store in a browser")
        overlayView.onAction = { [weak self] in
            self?.statusFilter = nil
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


// MARK: - Convenience Methods
//
private extension OrdersViewController {

    func detailsViewModel(at indexPath: IndexPath) -> OrderDetailsViewModel {
        let order = resultsController.object(at: indexPath)

        return OrderDetailsViewModel(order: order)
    }

    func lookUpOrderStatus(for order: Order) -> OrderStatus? {
        for orderStatus in currentSiteStatuses where orderStatus.slug == order.statusKey {
            return orderStatus
        }

        return nil
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension OrdersViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderTableViewCell.reuseIdentifier, for: indexPath) as? OrderTableViewCell else {
            fatalError()
        }

        let viewModel = detailsViewModel(at: indexPath)
        let orderStatus = lookUpOrderStatus(for: viewModel.order)
        cell.configureCell(viewModel: viewModel, orderStatus: orderStatus)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let rawAge = resultsController.sections[section].name
        return Age(rawValue: rawAge)?.description
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension OrdersViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Settings.estimatedHeaderHeight
    }

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

        guard state != .placeholder else {
            return
        }

        performSegue(withIdentifier: Segues.orderDetails, sender: detailsViewModel(at: indexPath))
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let orderIndex = resultsController.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: orderIndex)

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid yout yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height
    }
}


// MARK: - Segues
//
extension OrdersViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let singleOrderViewController = segue.destination as? OrderDetailsViewController, let viewModel = sender as? OrderDetailsViewModel else {
            return
        }

        ServiceLocator.analytics.track(.orderOpen, withProperties: ["id": viewModel.order.orderID,
                                                               "status": viewModel.order.statusKey])
        singleOrderViewController.viewModel = viewModel
    }
}


// MARK: - Finite State Machine Management
//
private extension OrdersViewController {

    func didEnter(state: State) {
        switch state {
        case .emptyUnfiltered:
            displayEmptyUnfilteredOverlay()
        case .emptyFiltered:
            displayEmptyFilteredOverlay()
        case .placeholder:
            displayPlaceholderOrders()
        case .syncing:
            ensureFooterSpinnerIsStarted()
        case .results:
            break
        }
    }

    func didLeave(state: State) {
        switch state {
        case .emptyFiltered:
            removeAllOverlays()
        case .emptyUnfiltered:
            removeAllOverlays()
        case .placeholder:
            removePlaceholderOrders()
        case .syncing:
            ensureFooterSpinnerIsStopped()
        case .results:
            break
        }
    }

    /// Should be called before Sync'ing. Transitions to either `results` or `placeholder` state, depending on whether if
    /// we've got cached results, or not.
    ///
    func transitionToSyncingState() {
        state = isEmpty ? .placeholder : .syncing
    }

    /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
    /// Transitions to `.results` / `.emptyFiltered` / `.emptyUnfiltered` accordingly.
    ///
    func transitionToResultsUpdatedState() {
        if isEmpty == false {
            state = .results
            return
        }

        if isFiltered {
            state = .emptyFiltered
            return
        }

        state = .emptyUnfiltered
    }
}


// MARK: - Nested Types
//
private extension OrdersViewController {

    enum FilterAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let displayAll = NSLocalizedString(
            "All",
            comment: "Name of the All filter on the Order List screen - it means all orders will be displayed."
        )
    }

    enum Settings {
        static let estimatedHeaderHeight = CGFloat(43)
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }

    enum Segues {
        static let orderDetails = "ShowOrderDetailsViewController"
    }

    enum State {
        case placeholder
        case syncing
        case results
        case emptyUnfiltered
        case emptyFiltered
    }
}
