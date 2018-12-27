import Foundation
import UIKit
import Yosemite


/// OrderSearchViewController: Displays the "Search Orders" Interface
///
class OrderSearchViewController: UIViewController {

    /// Dismiss Action
    ///
    @IBOutlet private var cancelButton: UIButton!

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

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Search Store ID
    ///
    private let storeID: Int



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

    /// Setup: Results Controller
    ///
    func configureResultsController() {
        resultsController.startForwardingEvents(to: tableView)
        try? resultsController.performFetch()
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
        let keyword = searchBar.text ?? String()
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
        let action = OrderAction.searchOrders(siteID: storeID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize) { error in
            if let error = error {
                DDLogError("☠️ Order Search Failure! \(error)")
            }

            onCompletion?(error == nil)
        }

        StoresManager.shared.dispatch(action)
        DDLogInfo("🔍 Searching for Orders: [\(keyword)]...")
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
        return OrderDetailsViewModel(order: order)
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


// MARK: - Private Types
//
private enum Settings {
    static let estimatedHeaderHeight = CGFloat(43)
    static let estimatedRowHeight = CGFloat(86)
}
