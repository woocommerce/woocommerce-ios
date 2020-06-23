import UIKit
import Gridicons
import Yosemite
import WordPressUI
import SafariServices
import StoreKit

// Used for protocol conformance of IndicatorInfoProvider only.
import XLPagerTabStrip

private typealias SyncReason = OrdersViewModel.SyncReason

protocol OrdersViewControllerDelegate: class {
    /// Called when `OrdersViewController` is about to fetch Orders from the API.
    ///
    func ordersViewControllerWillSynchronizeOrders(_ viewController: OrdersViewController)
}

/// OrdersViewController: Displays the list of Orders associated to the active Store / Account.
///
final class OrdersViewController: UIViewController {

    weak var delegate: OrdersViewControllerDelegate?

    private let viewModel: OrdersViewModel

    /// Main TableView.
    ///
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

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

    /// The configuration to use for the view if the list is empty.
    ///
    private let emptyStateConfig: EmptyStateViewController.Config

    /// The view shown if the list is empty.
    ///
    private lazy var emptyStateViewController = EmptyStateViewController(style: .list)

    /// Used for looking up the `OrderStatus` to show in the `OrderTableViewCell`.
    ///
    /// The `OrderStatus` data is fetched from the API by `OrdersMasterViewModel`.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// The current list of order statuses for the default site
    ///
    private var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
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
    init(title: String, viewModel: OrdersViewModel, emptyStateConfig: EmptyStateViewController.Config) {
        self.viewModel = viewModel
        self.emptyStateConfig = emptyStateConfig

        super.init(nibName: nil, bundle: nil)

        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableViewHeadersAndCells()
        configureTableView()
        configureGhostableTableView()

        refreshStatusPredicate()
        configureStatusResultsController()

        configureViewModel()
        configureSyncingCoordinator()

        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncingCoordinator.resynchronize()

        // Fix any _incomplete_ animation if the orders were deleted and refetched from
        // a different location (or Orders tab).
        tableView.reloadData()
    }
}


// MARK: - User Interface Initialization
//
private extension OrdersViewController {
    /// Initialize ViewModel operations
    ///
    func configureViewModel() {
        viewModel.onShouldResynchronizeIfViewIsVisible = { [weak self] in
            guard let self = self,
                  // Avoid synchronizing if the view is not visible. The refresh will be handled in
                  // `viewWillAppear` instead.
                  self.viewIfLoaded?.window != nil else {
                return
            }

            self.syncingCoordinator.resynchronize()
        }

        viewModel.activateAndForwardUpdates(to: tableView)
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

    /// Setup: Status Results Controller
    ///
    func configureStatusResultsController() {
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
        tableView.delegate = self
        tableView.dataSource = self

        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = footerSpinnerView
        tableView.estimatedSectionHeaderHeight = Settings.estimatedHeaderHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = .leastNonzeroMagnitude
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)
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

    /// Registers all of the available table view cells and headers
    ///
    func registerTableViewHeadersAndCells() {
        let cells = [ OrderTableViewCell.self ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
            ghostableTableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }

        let headerType = TwoColumnSectionHeaderView.self
        tableView.register(headerType.loadNib(), forHeaderFooterViewReuseIdentifier: headerType.reuseIdentifier)
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
        syncingCoordinator.resynchronize(reason: SyncReason.pullToRefresh.rawValue) {
            sender.endRefreshing()
        }
    }
}

// MARK: - Sync'ing Helpers
//
extension OrdersViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Orders for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)? = nil) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            onCompletion?(false)
            return
        }

        transitionToSyncingState()

        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            reason: SyncReason(rawValue: reason ?? "")) { [weak self] error in
                guard let self = self else {
                    return
                }

                if let error = error {
                    DDLogError("⛔️ Error synchronizing orders: \(error)")
                    self.displaySyncingErrorNotice(pageNumber: pageNumber, pageSize: pageSize, reason: reason)
                } else {
                    let status = self.viewModel.statusFilter?.slug ?? String()
                    ServiceLocator.analytics.track(.ordersListLoaded, withProperties: ["status": status])
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

        return highestPageBeingSynced * SyncingCoordinator.Defaults.pageSize > viewModel.numberOfObjects
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
    func displaySyncingErrorNotice(pageNumber: Int, pageSize: Int, reason: String?) {
        let message = NSLocalizedString("Unable to refresh list", comment: "Refresh Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            guard let self = self else {
                return
            }

            self.delegate?.ordersViewControllerWillSynchronizeOrders(self)
            self.sync(pageNumber: pageNumber, pageSize: pageSize, reason: reason)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Shows the EmptyStateViewController
    ///
    func displayEmptyViewController() {
        let childController = emptyStateViewController

        // Abort if we are already displaying this childController
        guard childController.parent == nil else {
            return
        }
        guard let childView = childController.view else {
            return
        }

        childController.configure(emptyStateConfig)

        childView.translatesAutoresizingMaskIntoConstraints = false

        addChild(childController)
        view.addSubview(childView)
        NSLayoutConstraint.activate([
            childView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            childView.topAnchor.constraint(equalTo: tableView.topAnchor),
            childView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
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


// MARK: - Convenience Methods
//
private extension OrdersViewController {

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
        viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderTableViewCell.reuseIdentifier, for: indexPath) as? OrderTableViewCell else {
            fatalError()
        }

        let detailsViewModel = viewModel.detailsViewModel(at: indexPath)
        let orderStatus = lookUpOrderStatus(for: detailsViewModel.order)
        cell.configureCell(viewModel: detailsViewModel, orderStatus: orderStatus)
        cell.layoutIfNeeded()
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let reuseIdentifier = TwoColumnSectionHeaderView.reuseIdentifier
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as? TwoColumnSectionHeaderView else {
            return nil
        }

        header.leftText = {
            let rawAge = viewModel.sectionInfo(at: section).name
            return Age(rawValue: rawAge)?.description
        }()
        header.rightText = nil

        return header
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension OrdersViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard state != .placeholder else {
            return
        }

        guard let orderDetailsVC = OrderDetailsViewController.instantiatedViewControllerFromStoryboard() else {
            assertionFailure("Expected OrderDetailsViewController to be instantiated")
            return
        }
        let orderDetailsViewModel = viewModel.detailsViewModel(at: indexPath)
        orderDetailsVC.viewModel = orderDetailsViewModel

        ServiceLocator.analytics.track(.orderOpen, withProperties: ["id": orderDetailsViewModel.order.orderID,
        "status": orderDetailsViewModel.order.statusKey])

        navigationController?.pushViewController(orderDetailsVC, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let orderIndex = viewModel.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: orderIndex)
    }
}

// MARK: - Finite State Machine Management
//
private extension OrdersViewController {

    func didEnter(state: State) {
        switch state {
        case .empty:
            displayEmptyViewController()
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
        case .empty:
            removeEmptyViewController()
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
        state = viewModel.isEmpty ? .placeholder : .syncing
    }

    /// Should be called whenever the results are updated: after Sync'ing (or after applying a filter).
    /// Transitions to `.results` or `.empty`.
    ///
    func transitionToResultsUpdatedState() {
        state = viewModel.isEmpty ? .empty : .results
    }
}

// MARK: - IndicatorInfoProvider Conformance

// This conformance is not used directly by `OrdersViewController`. We only need this because
// `Self` is used as a child of `OrdersMasterViewController` which is a
// `ButtonBarPagerTabStripViewController`.
extension OrdersViewController: IndicatorInfoProvider {
    /// Return `self.title` under `IndicatorInfo`.
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
        case empty
    }
}
