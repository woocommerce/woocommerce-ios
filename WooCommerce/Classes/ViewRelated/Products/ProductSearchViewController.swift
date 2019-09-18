import UIKit
import Yosemite

/// ProductSearchViewController: Displays the "Search Products" Interface
///
class ProductSearchViewController: UIViewController {

    /// Top container view that contains search bar, cancel button 
    ///
    private lazy var topContainerView: BordersView = BordersView(frame: .zero)

    /// Dismiss Action
    ///
    private lazy var cancelButton: UIButton = UIButton(frame: .zero)

    /// Empty State Legend
    ///
    private lazy var emptyStateLabel: UILabel = UILabel(frame: .zero)

    /// Main SearchBar
    ///
    private lazy var searchBar: UISearchBar = UISearchBar(frame: .zero)

    /// TableView
    ///
    private lazy var tableView: UITableView = UITableView(frame: .zero, style: .grouped)

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Orders in sync.
    ///
    private lazy var resultsController: ResultsController<StorageProduct> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageProduct.dateCreated, ascending: false)

        return ResultsController<StorageProduct>(storageManager: storageManager, sortedBy: [descriptor])
    }()

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    /// Search Store ID
    ///
    private let storeID: Int

    /// Indicates if there are results onscreen.
    ///
    private var hasData: Bool {
        return !resultsController.isEmpty
    }

    /// Returns the active Keyword
    ///
    private var keyword: String {
        return searchBar.text ?? String()
    }

    /// Coordinates view controller UI state.
    ///
    private lazy var stateCoordinator: ProductSearchViewControllerStateCoordinator = {
        let stateCoordinator = ProductSearchViewControllerStateCoordinator(onLeavingState: { [weak self] state in
            self?.didLeave(state: state)
            }, onEnteringState: { [weak self] state in
                self?.didEnter(state: state)
        })
        return stateCoordinator
    }()

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
        configureSubviews()
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
private extension ProductSearchViewController {

    /// Setup: Main View
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Setup: layout subviews
    func configureSubviews() {
        configureTopContainerView()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: topContainerView.bottomAnchor)
            ])

        view.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            emptyStateLabel.topAnchor.constraint(equalTo: topContainerView.bottomAnchor, constant: 100),
            emptyStateLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
    }

    func configureTopContainerView() {
        topContainerView.bottomVisible = true
        view.addSubview(topContainerView)
        topContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            view.topAnchor.constraint(equalTo: topContainerView.topAnchor)
            ])

        topContainerView.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor, constant: 8),
            searchBar.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            ])

        topContainerView.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor, constant: -1),
            cancelButton.leadingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: 3)
            ])
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedRowHeight = Settings.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = footerSpinnerView
    }

    /// Setup: Search Bar
    ///
    func configureSearchBar() {
        searchBar.delegate = self

        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = NSLocalizedString("Search all products", comment: "Products Search Placeholder")
        searchBar.tintColor = .black
    }

    /// Setup: Actions
    ///
    func configureActions() {
        let title = NSLocalizedString("Cancel", comment: "")
        cancelButton.setTitle(title, for: .normal)
        cancelButton.applyLinkButtonStyle()
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 16)
        cancelButton.titleLabel?.font = UIFont.body
        cancelButton.addTarget(self, action: #selector(dismissWasPressed), for: .touchUpInside)
    }

    /// Setup: No Results
    ///
    func configureEmptyStateLabel() {
        emptyStateLabel.text = NSLocalizedString("No products found", comment: "Search Products (Empty State)")
        emptyStateLabel.textColor = StyleManager.wooGreyMid
        emptyStateLabel.font = .headline
        emptyStateLabel.adjustsFontForContentSizeCategory = true
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.textAlignment = .center
    }

    /// Setup: Results Controller
    ///
    func configureResultsController() {
        resultsController.startForwardingEvents(to: tableView)
        try? resultsController.performFetch()
        stateCoordinator.transitionToResultsUpdatedState(hasData: hasData)
    }

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        tableView.register(ProductsTabProductTableViewCell.self, forCellReuseIdentifier: ProductsTabProductTableViewCell.reuseIdentifier)
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
extension ProductSearchViewController {

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
extension ProductSearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        synchronizeSearchResults(with: searchText)
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}


// MARK: - SyncingCoordinatorDelegate Conformance
//
extension ProductSearchViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Products for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)? = nil) {
        synchronizeProducts(keyword: keyword, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
    }
}


// MARK: - Actions
//
private extension ProductSearchViewController {

    /// Updates the Predicate + Triggers a Sync Event
    ///
    func synchronizeSearchResults(with keyword: String) {
        resultsController.predicate = NSPredicate(format: "ANY searchResults.keyword = %@", keyword)

        tableView.setContentOffset(.zero, animated: false)
        tableView.reloadData()

        syncingCoordinator.resynchronize()
    }

    /// Synchronizes the Products matching a given Keyword
    ///
    func synchronizeProducts(keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = ProductAction.searchProducts(siteID: storeID,
                                                  keyword: keyword,
                                                  pageNumber: pageNumber,
                                                  pageSize: pageSize) { [weak self] error in
                                                    guard let self = self else {
                                                        return
                                                    }

                                                    if let error = error {
                                                        DDLogError("☠️ Product Search Failure! \(error)")
                                                    }

                                                    // Disregard OPs that don't really match the latest keyword
                                                    if keyword == self.keyword {
                                                        self.stateCoordinator.transitionToResultsUpdatedState(hasData: self.hasData)
                                                    }

                                                    onCompletion?(error == nil)
        }

        stateCoordinator.transitionToSyncingState()
        ServiceLocator.stores.dispatch(action)
        // TODO-1263: analytics
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ProductSearchViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductsTabProductTableViewCell.reuseIdentifier, for: indexPath) as? ProductsTabProductTableViewCell else {
            fatalError()
        }

        let product = resultsController.object(at: indexPath)
        let viewModel = ProductsTabProductViewModel(product: product)
        cell.update(viewModel: viewModel)

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension ProductSearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let product = resultsController.object(at: indexPath)
        let viewModel = ProductDetailsViewModel(product: product)
        let productViewController = ProductDetailsViewController(viewModel: viewModel)
        navigationController?.pushViewController(productViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let orderIndex = resultsController.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: orderIndex)
    }
}


// MARK: - Actions
//
extension ProductSearchViewController {

    @IBAction func dismissWasPressed() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - Spinner Helpers
//
extension ProductSearchViewController {

    /// Starts the Footer Spinner animation, whenever `mustStartFooterSpinner` returns *true*.
    ///
    private func ensureFooterSpinnerIsStarted() {
        guard mustStartFooterSpinner() else {
            return
        }

        footerSpinnerView.startAnimating()
    }

    /// Whenever we're sync'ing an Products Page that's beyond what we're currently displaying, this method will return *true*.
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
private extension ProductSearchViewController {

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
private extension ProductSearchViewController {

    func didEnter(state: ProductSearchViewControllerState) {
        switch state {
        case .noResultsPlaceholder:
            displayEmptyState()
        case .syncing:
            ensureFooterSpinnerIsStarted()
        case .results:
            break
        }
    }

    func didLeave(state: ProductSearchViewControllerState) {
        switch state {
        case .noResultsPlaceholder:
            removeEmptyState()
        case .syncing:
            ensureFooterSpinnerIsStopped()
        case .results:
            break
        }
    }
}


// MARK: - Private Settings
//
private enum Settings {
    static let estimatedHeaderHeight = CGFloat(43)
    static let estimatedRowHeight = CGFloat(86)
}
