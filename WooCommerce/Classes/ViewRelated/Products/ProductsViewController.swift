import UIKit
import WordPressUI
import Yosemite

/// Shows a list of products with pull to refresh and infinite scroll
///
final class ProductsViewController: UIViewController {

    /// Main TableView
    ///
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        return tableView
    }()

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Products in sync.
    ///
    private lazy var resultsController: ResultsController<StorageProduct> = {
        let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min
        let resultsController = createResultsController(siteID: siteID)
        configureResultsController(resultsController) { [weak self] in
            self?.tableView.reloadData()
        }
        return resultsController
    }()

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        return resultsController.isEmpty
    }

    /// SyncCoordinator: Keeps tracks of which pages have been refreshed, and encapsulates the "What should we sync now" logic.
    ///
    private let syncingCoordinator = SyncingCoordinator()

    private lazy var stateCoordinator: ProductsViewControllerStateCoordinator = {
        let stateCoordinator = ProductsViewControllerStateCoordinator(onLeavingState: { [weak self] state in
            self?.didLeave(state: state)
            }, onEnteringState: { [weak self] state in
                self?.didEnter(state: state)
        })
        return stateCoordinator
    }()

    // MARK: - View Lifecycle

    deinit {
        stopListeningToNotifications()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureTableView()
        configureSyncingCoordinator()
        registerTableViewCells()

        startListeningToNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            assertionFailure("No valid site ID for Products tab")
            return
        }
        updateResultsController(siteID: siteID)
        syncingCoordinator.synchronizeFirstPage()

        if AppRatingManager.shared.shouldPromptForAppReview() {
            displayRatingPrompt()
        }
    }

}

// MARK: - Notifications
//
private extension ProductsViewController {

    /// Wires all of the Notification Hooks
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultAccountWasUpdated), name: .defaultAccountWasUpdated, object: nil)
        nc.addObserver(self, selector: #selector(defaultSiteWasUpdated), name: .StoresManagerDidUpdateDefaultSite, object: nil)
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
        syncingCoordinator.resetInternalState()
    }

    /// Default Site Updated Handler
    ///
    @objc func defaultSiteWasUpdated() {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }
        updateResultsController(siteID: siteID)
        tableView.reloadData()
    }
}

// MARK: - Navigation Bar Actions
//
private extension ProductsViewController {
    @IBAction func displaySearchProducts() {
        guard let storeID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        // TODO-1263: analytics
        let searchViewController = ProductSearchViewController(storeID: storeID)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - View Configuration
//
private extension ProductsViewController {

    /// Set the title.
    ///
    func configureNavigationBar() {
        title = NSLocalizedString(
            "Products",
            comment: "Title that appears on top of the Product List screen (plural form of the word Product)."
        )

        navigationItem.leftBarButtonItem = {
            let button = UIBarButtonItem(image: .searchImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(displaySearchProducts))
            button.tintColor = .white
            button.accessibilityTraits = .button
            button.accessibilityLabel = NSLocalizedString("Search products", comment: "Search Products")
            button.accessibilityHint = NSLocalizedString(
                "Retrieves a list of products that contain a given keyword.",
                comment: "VoiceOver accessibility hint, informing the user the button can be used to search products."
            )

            return button
        }()
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Configure common table properties.
    ///
    func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedRowHeight = Settings.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension

        // Removes extra header spacing in ghost content view.
        tableView.estimatedSectionHeaderHeight = 0
        tableView.sectionHeaderHeight = 0

        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = footerSpinnerView
    }

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        tableView.register(ProductsTabProductTableViewCell.self, forCellReuseIdentifier: ProductsTabProductTableViewCell.reuseIdentifier)
    }
}

// MARK: - Updates
//
private extension ProductsViewController {
    func updateResultsController(siteID: Int) {
        resultsController = createResultsController(siteID: siteID)
        configureResultsController(resultsController) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    func createResultsController(siteID: Int) -> ResultsController<StorageProduct> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
//        let predicate = NSPredicate(format: "siteID == %lld AND name = 'hi'", siteID)
        let descriptor = NSSortDescriptor(key: "dateModified", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }

    func configureResultsController(_ resultsController: ResultsController<StorageProduct>, onReload: @escaping () -> Void) {
        resultsController.onDidChangeContent = {
            onReload()
        }

        resultsController.onDidResetContent = {
            onReload()
        }

        try? resultsController.performFetch()
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductsTabProductTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? ProductsTabProductTableViewCell else {
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
extension ProductsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? Settings.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let product = resultsController.object(at: indexPath)
        let viewModel = ProductDetailsViewModel(product: product)
        let productViewController = ProductDetailsViewController(viewModel: viewModel)
        navigationController?.pushViewController(productViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let productIndex = resultsController.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: productIndex)

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid yout yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height
    }
}

private extension ProductsViewController {
    @objc private func pullToRefresh(sender: UIRefreshControl) {
        // TODO-1263: analytics
        syncingCoordinator.synchronizeFirstPage {
            sender.endRefreshing()
        }
    }
}

// MARK: - Placeholders
//
private extension ProductsViewController {

    /// Renders the Placeholder Orders: For safety reasons, we'll also halt ResultsController <> UITableView glue.
    ///
    func displayPlaceholderProducts() {
        let options = GhostOptions(reuseIdentifier: ProductsTabProductTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options)

        resultsController.stopForwardingEvents()
    }

    /// Removes the Placeholder Products (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderProducts() {
        tableView.removeGhostContent()
        resultsController.startForwardingEvents(to: tableView)
        tableView.reloadData()
    }

    /// Displays the Error Notice.
    ///
    func displaySyncingErrorNotice(pageNumber: Int, pageSize: Int) {
        let message = NSLocalizedString("Unable to refresh list", comment: "Refresh Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.sync(pageNumber: pageNumber, pageSize: pageSize)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the overlay when there are no results.
    ///
    func displayNoResultsOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = nil
        overlayView.messageText = NSLocalizedString("No products yet",
                                                    comment: "The text on the placeholder overlay when there are no products on the Products tab")
        overlayView.actionVisible = false
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

// MARK: - Sync'ing Helpers
//
extension ProductsViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Products for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)? = nil) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            onCompletion?(false)
            return
        }

        transitionToSyncingState()

        let action = ProductAction
            .synchronizeProducts(siteID: siteID,
                                 pageNumber: pageNumber,
                                 pageSize: pageSize) { [weak self] error in
                                    guard let self = self else {
                                        return
                                    }

                                    if let error = error {
                                        DDLogError("⛔️ Error synchronizing products: \(error)")
                                        self.displaySyncingErrorNotice(pageNumber: pageNumber, pageSize: pageSize)
                                    } else {
                                        // TODO-1263: analytics
                                    }

                                    self.transitionToResultsUpdatedState()
                                    onCompletion?(error == nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - Finite State Machine Management
//
private extension ProductsViewController {

    func didEnter(state: ProductsViewControllerState) {
        switch state {
        case .noResultsPlaceholder:
            displayNoResultsOverlay()
        case .syncing(let withExistingData):
            if withExistingData {
                ensureFooterSpinnerIsStarted()
            } else {
                displayPlaceholderProducts()
            }
        case .results:
            break
        }
    }

    func didLeave(state: ProductsViewControllerState) {
        switch state {
        case .noResultsPlaceholder:
            removeAllOverlays()
        case .syncing:
            ensureFooterSpinnerIsStopped()
            removePlaceholderProducts()
        case .results:
            break
        }
    }

    func transitionToSyncingState() {
        stateCoordinator.transitionToSyncingState(withExistingData: !isEmpty)
    }

    func transitionToResultsUpdatedState() {
        stateCoordinator.transitionToResultsUpdatedState(hasData: !isEmpty)
    }
}

// MARK: - Spinner Helpers
//
extension ProductsViewController {

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

// MARK: - Nested Types
//
private extension ProductsViewController {

    enum Settings {
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }
}
