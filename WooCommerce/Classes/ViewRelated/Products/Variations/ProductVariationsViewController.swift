import UIKit
import WordPressUI
import Yosemite

/// Displays a paginated list of Product Variations with its price or visibility.
///
final class ProductVariationsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

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

    private lazy var footerEmptyView = {
        return UIView(frame: .zero)
    }()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Product Variations in sync.
    ///
    private lazy var resultsController: ResultsController<StorageProductVariation> = {
        let resultsController = createResultsController()
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

    private lazy var stateCoordinator: PaginatedListViewControllerStateCoordinator = {
        let stateCoordinator = PaginatedListViewControllerStateCoordinator(onLeavingState: { [weak self] state in
            self?.didLeave(state: state)
            }, onEnteringState: { [weak self] state in
                self?.didEnter(state: state)
        })
        return stateCoordinator
    }()

    private let siteID: Int64
    private let productID: Int64

    init(siteID: Int64, productID: Int64) {
        self.siteID = siteID
        self.productID = productID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureTableView()
        configureSyncingCoordinator()
        registerTableViewCells()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        syncingCoordinator.synchronizeFirstPage()
    }
}


// MARK: - View Configuration
//
private extension ProductVariationsViewController {

    /// Set the title.
    ///
    func configureNavigationBar() {
        title = NSLocalizedString(
            "Variations",
            comment: "Title that appears on top of the Product Variation List screen."
        )
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    /// Configure common table properties.
    ///
    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedRowHeight = Settings.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension

        // Removes extra header spacing in ghost content view.
        tableView.estimatedSectionHeaderHeight = 0
        tableView.sectionHeaderHeight = 0

        tableView.backgroundColor = .listBackground
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

// MARK: - ResultsController
//
private extension ProductVariationsViewController {
    func createResultsController() -> ResultsController<StorageProductVariation> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "product.siteID == %lld AND product.productID == %lld", siteID, productID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductVariation.menuOrder, ascending: true)

        return ResultsController<StorageProductVariation>(storageManager: storageManager,
                                                          matching: predicate,
                                                          sortedBy: [descriptor])
    }

    func configureResultsController(_ resultsController: ResultsController<StorageProductVariation>, onReload: @escaping () -> Void) {
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
extension ProductVariationsViewController: UITableViewDataSource {

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

        let productVariation = resultsController.object(at: indexPath)

        let currencyCode = CurrencySettings.shared.currencyCode
        let currency = CurrencySettings.shared.symbol(from: currencyCode)
        let viewModel = ProductsTabProductViewModel(productVariation: productVariation,
                                                    currency: currency)
        cell.update(viewModel: viewModel)
        cell.selectionStyle = .none

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension ProductVariationsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? Settings.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

private extension ProductVariationsViewController {
    @objc private func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.productVariationListPulledToRefresh)

        syncingCoordinator.synchronizeFirstPage {
            sender.endRefreshing()
        }
    }
}

// MARK: - Placeholders
//
private extension ProductVariationsViewController {

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
        overlayView.messageText = NSLocalizedString("No product variations yet",
                                                    comment: "The text on the placeholder overlay when there are no product variations on the Products tab")
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
extension ProductVariationsViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Product Variations for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)? = nil) {
        transitionToSyncingState()

        let action = ProductVariationAction
            .synchronizeProductVariations(siteID: Int64(siteID), productID: productID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] error in
                                    guard let self = self else {
                                        return
                                    }

                                    if let error = error {
                                        ServiceLocator.analytics.track(.productVariationListLoadError, withError: error)

                                        DDLogError("⛔️ Error synchronizing product variations: \(error)")
                                        self.displaySyncingErrorNotice(pageNumber: pageNumber, pageSize: pageSize)
                                    } else {
                                        ServiceLocator.analytics.track(.productVariationListLoaded)
                                    }

                                    self.transitionToResultsUpdatedState()
                                    onCompletion?(error == nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - Finite State Machine Management
//
private extension ProductVariationsViewController {

    func didEnter(state: PaginatedListViewControllerState) {
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

    func didLeave(state: PaginatedListViewControllerState) {
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
extension ProductVariationsViewController {

    /// Starts the Footer Spinner animation, whenever `mustStartFooterSpinner` returns *true*.
    ///
    private func ensureFooterSpinnerIsStarted() {
        guard mustStartFooterSpinner() else {
            return
        }

        tableView.tableFooterView = footerSpinnerView
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
        tableView.tableFooterView = footerEmptyView
    }
}

// MARK: - Nested Types
//
private extension ProductVariationsViewController {

    enum Settings {
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
    }
}
