import Foundation
import UIKit
import Yosemite
import WordPressUI


/// OrderSearchViewController: Displays the "Search Orders" Interface
///
class OrderSearchViewController: UIViewController {

    /// Dismiss Action
    ///
    @IBOutlet private var cancelButton: UIButton!

    /// Empty State Legend
    ///
    @IBOutlet private var emptyStateLabel: UILabel!

    /// Main SearchBar
    ///
    @IBOutlet private var searchBar: UISearchBar!

    /// TableView
    ///
    @IBOutlet private var tableView: UITableView!

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Orders in sync.
    ///
    private lazy var resultsController: ResultsController<StorageOrder> = {
        let storageManager = AppDelegate.shared.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)

        return ResultsController<StorageOrder>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) OrderStatuses in sync.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Search Store ID
    ///
    private let storeID: Int

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        return resultsController.isEmpty
    }

    /// Returns the active Keyword
    ///
    private var keyword: String {
        return searchBar.text ?? String()
    }

    /// UI Active State
    ///
    private var state: State = .results {
        didSet {
            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }


    /// Deinitializer
    ///
    deinit {
        stopListeningToNotifications()
    }

    /// Designated Initializer
    ///
    init(storeID: Int) {
        self.storeID = storeID
        super.init(nibName: nil, bundle: nil)
    }

    /// Unsupported: NSCoder
    ///
    required init?(coder aDecoder: NSCoder) {
        assertionFailure()
        return nil
    }


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableViewCells()

        configureSyncingCoordinator()
        configureActions()
        configureEmptyStateLabel()
        configureMainView()
        configureSearchBar()
        configureTableView()
        configureResultsController()

        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
        searchBar.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}


// MARK: - User Interface Initialization
//
private extension OrderSearchViewController {

    /// Setup: Main View
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedRowHeight = Settings.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = footerSpinnerView
    }

    /// Setup: Search Bar
    ///
    func configureSearchBar() {
        searchBar.placeholder = NSLocalizedString("Search all orders", comment: "Orders Search Placeholder")
        searchBar.tintColor = .black
    }

    /// Setup: Actions
    ///
    func configureActions() {
        let title = NSLocalizedString("Cancel", comment: "")
        cancelButton.setTitle(title, for: .normal)
        cancelButton.titleLabel?.font = UIFont.body
    }

    /// Setup: No Results
    ///
    func configureEmptyStateLabel() {
        emptyStateLabel.text = NSLocalizedString("No Orders found", comment: "Search Orders (Empty State)")
        emptyStateLabel.textColor = StyleManager.wooGreyMid
        emptyStateLabel.font = .headline
    }

    /// Setup: Results Controller
    ///
    func configureResultsController() {
        resultsController.startForwardingEvents(to: tableView)
        try? resultsController.performFetch()
        try? statusResultsController.performFetch()
    }

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [ OrderTableViewCell.self ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    /// Unregisters from the Notification Center
    ///
    func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - Notifications
//
extension OrderSearchViewController {

    /// Executed whenever `UIResponder.keyboardWillShowNotification` note is posted
    ///
    @objc func keyboardWillShow(_ note: Notification) {
        let bottomInset = keyboardHeight(from: note)

        tableView.contentInset.bottom = bottomInset
        tableView.scrollIndicatorInsets.bottom = bottomInset
    }

    /// Returns the Keyboard Height from a (hopefully) Keyboard Notification.
    ///
    func keyboardHeight(from note: Notification) -> CGFloat {
        let wrappedRect = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? .zero

        return keyboardRect.height
    }
}


// MARK: - UISearchBarDelegate Conformance
//
extension OrderSearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        synchronizeSearchResults(with: searchText)
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}


// MARK: - SyncingCoordinatorDelegate Conformance
//
extension OrderSearchViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Orders for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)? = nil) {
        synchronizeOrders(keyword: keyword, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
    }
}


// MARK: - Actions
//
private extension OrderSearchViewController {

    /// Updates the Predicate + Triggers a Sync Event
    ///
    func synchronizeSearchResults(with keyword: String) {
        resultsController.predicate = NSPredicate(format: "ANY searchResults.keyword = %@", keyword)

        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()

        syncingCoordinator.resynchronize()
    }

    /// Synchronizes the Orders matching a given Keyword
    ///
    func synchronizeOrders(keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = OrderAction.searchOrders(siteID: storeID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize) { [weak self] error in
            if let error = error {
                DDLogError("☠️ Order Search Failure! \(error)")
            }

            // Disregard OPs that don't really match the latest keyword
            if keyword == self?.keyword {
                self?.transitionToResultsUpdatedState()
            }

            onCompletion?(error == nil)
        }

        transitionToSyncingState()
        StoresManager.shared.dispatch(action)
        WooAnalytics.shared.track(.ordersListFilterOrSearch, withProperties: ["filter": "", "search": "\(keyword)"])
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension OrderSearchViewController: UITableViewDataSource {

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
        cell.configureCell(viewModel: viewModel)

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension OrderSearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentOrderDetails(for: detailsViewModel(at: indexPath))
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let orderIndex = resultsController.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: orderIndex)
    }
}


// MARK: - Convenience Methods
//
private extension OrderSearchViewController {

    func detailsViewModel(at indexPath: IndexPath) -> OrderDetailsViewModel {
        let order = resultsController.object(at: indexPath)
        let orderStatus = lookUpOrderStatus(for: order)

        return OrderDetailsViewModel(order: order, orderStatus: orderStatus)
    }

    func lookUpOrderStatus(for order: Order) -> OrderStatus? {
        let listAll = statusResultsController.fetchedObjects
        for orderStatus in listAll where orderStatus.slug == order.statusKey {
            return orderStatus
        }

        return nil
    }
}


// MARK: - Actions
//
extension OrderSearchViewController {

    @IBAction func dismissWasPressed() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }

    private func presentOrderDetails(for order: OrderDetailsViewModel) {
        let identifier = OrderDetailsViewController.classNameWithoutNamespaces
        guard let detailsViewController = UIStoryboard.orders.instantiateViewController(withIdentifier: identifier) as? OrderDetailsViewController else {
            fatalError()
        }

        detailsViewController.viewModel = order

        navigationController?.pushViewController(detailsViewController, animated: true)
    }
}


// MARK: - Spinner Helpers
//
extension OrderSearchViewController {

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


// MARK: - Placeholders
//
private extension OrderSearchViewController {

    /// Displays the Empty State Legend.
    ///
    func displayEmptyState() {
        emptyStateLabel.isHidden = false
    }

    /// Removes the Empty State Legend.
    ///
    func removeEmptyState() {
        emptyStateLabel.isHidden = true
    }
}


// MARK: - FSM
//
private extension OrderSearchViewController {

    func didEnter(state: State) {
        switch state {
        case .empty:
            displayEmptyState()
        case .syncing:
            ensureFooterSpinnerIsStarted()
        case .results:
            break
        }
    }

    func didLeave(state: State) {
        switch state {
        case .empty:
            removeEmptyState()
        case .syncing:
            ensureFooterSpinnerIsStopped()
        case .results:
            break
        }
    }

    /// Should be called before Sync'ing. Transitions to either `results` state.
    ///
    func transitionToSyncingState() {
        state = .syncing
    }

    /// Should be called whenever new results have been retrieved. Transitions to `.results` / `.empty` accordingly.
    ///
    func transitionToResultsUpdatedState() {
        state = isEmpty ? .empty : .results
    }
}


// MARK: - Private Settings
//
private enum Settings {
    static let estimatedHeaderHeight = CGFloat(43)
    static let estimatedRowHeight = CGFloat(86)
}


// MARK: - FSM States
//
private enum State {
    case syncing
    case results
    case empty
}
