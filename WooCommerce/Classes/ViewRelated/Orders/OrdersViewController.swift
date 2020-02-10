import UIKit
import Gridicons
import Yosemite
import WordPressUI
import SafariServices
import StoreKit

// Used for protocol conformance of IndicatorInfoProvider only.
import XLPagerTabStrip

protocol OrdersViewControllerDelegate: class {
    /// Called when `OrdersViewController` is about to fetch Orders from the API.
    ///
    func ordersViewControllerWillSynchronizeOrders(_ viewController: OrdersViewController)
    /// Called when `OrdersViewController` is requesting to reset the `statusFilter` to `nil`.
    ///
    /// `OrdersViewController` does not modify its own `statusFilter`. While it is capable of
    ///  doing that, we'd rather have that responsibility in the parent
    ///  `OrdersMasterViewController`.
    ///
    ///  TODO There are ways to make secure this intentional behavior. We are keeping this as is
    ///  for now since we will be significantly refactoring `OrdersViewController` later.
    ///
    func ordersViewControllerRequestsToClearStatusFilter(_ viewController: OrdersViewController)
}

/// OrdersViewController: Displays the list of Orders associated to the active Store / Account.
///
class OrdersViewController: UIViewController {

    weak var delegate: OrdersViewControllerDelegate?

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

    /// Used for looking up the `OrderStatus` to show in the `OrderTableViewCell`.
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
    /// This is set and changed by `OrdersMasterViewModel`. This shouldn't be updated internally
    /// by `self`.
    ///
    /// TODO Make this `let`.
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

    /// If `true`, the "Remove Filters" action will be shown on the Filtered Empty View.
    ///
    /// Defaults to `true`.
    ///
    /// - SeeAlso: displayEmptyFilteredOverlay
    ///
    private let showsRemoveFilterActionOnFilteredEmptyView: Bool

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

    // MARK: - View Lifecycle

    /// Designated initializer.
    ///
    /// - Parameter statusFilter The filter to use.
    ///
    init(title: String,
         statusFilter: OrderStatus? = nil,
         showsRemoveFilterActionOnFilteredEmptyView: Bool = true) {
        self.statusFilter = statusFilter
        self.showsRemoveFilterActionOnFilteredEmptyView = showsRemoveFilterActionOnFilteredEmptyView
        super.init(nibName: Self.nibName, bundle: nil)
        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshResultsPredicate()
        refreshStatusPredicate()
        registerTableViewCells()

        configureSyncingCoordinator()
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
    }

    /// Runs whenever the default Account is updated.
    ///
    @objc func defaultAccountWasUpdated() {
        refreshStatusPredicate()
        syncingCoordinator.resetInternalState()
    }
}

// MARK: - Actions
//
extension OrdersViewController {
    @objc func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.ordersListPulledToRefresh)
        delegate?.ordersViewControllerWillSynchronizeOrders(self)
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
            guard let self = self else {
                return
            }

            self.delegate?.ordersViewControllerWillSynchronizeOrders(self)
            self.sync(pageNumber: pageNumber, pageSize: pageSize)
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
            if let self = self {
                self.delegate?.ordersViewControllerRequestsToClearStatusFilter(self)
            }
        }

        overlayView.actionVisible = showsRemoveFilterActionOnFilteredEmptyView

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

        guard let orderDetailsVC = OrderDetailsViewController.instantiatedViewControllerFromStoryboard() else {
            assertionFailure("Expected OrderDetailsViewController to be instantiated")
            return
        }
        orderDetailsVC.viewModel = detailsViewModel(at: indexPath)

        navigationController?.pushViewController(orderDetailsVC, animated: true)
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

// MARK: - IndicatorInfoProvider Conformance

extension OrdersViewController: IndicatorInfoProvider {
    /// Return `self.title` under `IndicatorInfo`.
    ///
    /// This is not used directly by `OrdersViewController`. We only need this because `Self` is
    /// used as a child of `OrdersMasterViewController` which is a
    /// `ButtonBarPagerTabStripViewController`.
    ///
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        IndicatorInfo(title: title)
    }
}


// MARK: - Nested Types
//
private extension OrdersViewController {

    enum Settings {
        static let estimatedHeaderHeight = CGFloat(43)
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }

    enum State {
        case placeholder
        case syncing
        case results
        case emptyUnfiltered
        case emptyFiltered
    }
}
