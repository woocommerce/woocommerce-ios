import UIKit
import WordPressUI
import Yosemite

extension ListSelectorViewController: DrawerPresentable {
    // TODO-jc: fix height to fit to content
    var collapsedHeight: DrawerHeight {

        guard let tableView = tableView else {
            return .maxHeight
        }
        tableView.layoutIfNeeded()
        let size = tableView.contentSize
        let height = size.height +
            // TODO-jc: move these to an extension?
            BottomSheetViewController.Constants.gripHeight + BottomSheetViewController.Constants.Header.spacing + BottomSheetViewController.Constants.Stack.insets.top
        return .contentHeight(height)
    }

}

/// `ListSelectorDataSource` for selecting a Product Backorders Setting.
///
struct ProductSortOptionListSelectorDataSource: ListSelectorDataSource {
    typealias Model = ProductsSortOrder
    typealias Cell = BasicTableViewCell

    let data: [ProductsSortOrder] = [
        .dateDescending,
        .dateAscending,
        .nameDescending,
        .nameAscending
    ]

    var selected: ProductsSortOrder?

    init(selected: ProductsSortOrder?) {
        self.selected = selected
    }

    func configureCell(cell: BasicTableViewCell, model: ProductsSortOrder) {
        cell.selectionStyle = .default
        cell.textLabel?.text = model.actionSheetTitle
    }

    mutating func handleSelectedChange(selected: ProductsSortOrder) {
        self.selected = selected
    }

    func isSelected(model: ProductsSortOrder) -> Bool {
        return model == selected
    }
}

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
    private lazy var footerSpinnerView = {
        return FooterSpinnerView(tableViewStyle: tableView.style)
    }()

    private lazy var footerEmptyView = {
        return UIView(frame: .zero)
    }()

    /// Top stack view that is shown above the table view as the table header view.
    ///
    private lazy var topStackView: UIStackView = {
        let subviews = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.editProductsRelease2) ? [topBannerView, toolbar]: [topBannerView]
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /// Top toolbar that shows the sort and filter CTAs.
    ///
    private lazy var toolbar: UIView = {
        return createToolbar()
    }()

    /// Top banner that shows that the Products feature is still work in progress.
    ///
    private lazy var topBannerView: TopBannerView = {
        return createTopBannerView()
    }()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Products in sync.
    ///
    private lazy var resultsController: ResultsController<StorageProduct> = {
        let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        let resultsController = createResultsController(siteID: siteID)
        configureResultsController(resultsController) { [weak self] in
            self?.tableView.reloadData()
        }
        return resultsController
    }()

    private var sortOrder: ProductsSortOrder = .nameAscending {
        didSet {
            if sortOrder != oldValue {
                resultsController.updateSortOrder(sortOrder)
                syncingCoordinator.resynchronize {}
            }
        }
    }

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

    private let imageService: ImageService = ServiceLocator.imageService

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureTableView()
        configureSyncingCoordinator()
        registerTableViewCells()

        startListeningToNotifications()
        syncingCoordinator.resynchronize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            assertionFailure("No valid site ID for Products tab")
            return
        }
        updateResultsController(siteID: siteID)

        if AppRatingManager.shared.shouldPromptForAppReview() {
            displayRatingPrompt()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.updateHeaderHeight()
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
        navigationController?.popToRootViewController(animated: false)
        updateResultsController(siteID: siteID)
        tableView.reloadData()
        syncingCoordinator.resynchronize()
    }
}

// MARK: - Navigation Bar Actions
//
private extension ProductsViewController {
    @IBAction func displaySearchProducts() {
        guard let storeID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        ServiceLocator.analytics.track(.productListMenuSearchTapped)

        let searchViewController = SearchViewController(storeID: storeID,
                                                        command: ProductSearchUICommand(siteID: storeID),
                                                        cellType: ProductsTabProductTableViewCell.self)
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
            button.accessibilityTraits = .button
            button.accessibilityLabel = NSLocalizedString("Search products", comment: "Search Products")
            button.accessibilityHint = NSLocalizedString(
                "Retrieves a list of products that contain a given keyword.",
                comment: "VoiceOver accessibility hint, informing the user the button can be used to search products."
            )
            button.accessibilityIdentifier = "product-search-button"

            return button
        }()
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
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
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension

        // Removes extra header spacing in ghost content view.
        tableView.estimatedSectionHeaderHeight = 0
        tableView.sectionHeaderHeight = 0

        tableView.backgroundColor = .listBackground
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = footerSpinnerView
        tableView.separatorStyle = .none

        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: Int(Constants.headerDefaultHeight)))
        headerContainer.addSubview(topStackView)
        headerContainer.pinSubviewToSafeArea(topStackView, insets: Constants.headerContainerInsets)
        let bottomBorderView = UIView.createBorderView()
        headerContainer.addSubview(bottomBorderView)
        NSLayoutConstraint.activate([
            bottomBorderView.constrainToSuperview(attribute: .leading),
            bottomBorderView.constrainToSuperview(attribute: .trailing),
            bottomBorderView.constrainToSuperview(attribute: .bottom)
        ])
        tableView.tableHeaderView = headerContainer
    }

    func createToolbar() -> ToolbarView {
        let sortTitle = NSLocalizedString("Sort by", comment: "Title of the toolbar button to sort products in different ways.")
        let sortButton = UIButton(frame: .zero)
        sortButton.setTitle(sortTitle, for: .normal)
        sortButton.addTarget(self, action: #selector(sortButtonTapped(button:)), for: .touchUpInside)

        let filterTitle = NSLocalizedString("Filter", comment: "Title of the toolbar button to filter products by different attributes.")
        let filterButton = UIButton(frame: .zero)
        filterButton.setTitle(filterTitle, for: .normal)
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)

        [sortButton, filterButton].forEach {
            $0.applyLinkButtonStyle()
            $0.contentEdgeInsets = Constants.toolbarButtonInsets
        }

        let toolbar = ToolbarView()
        toolbar.backgroundColor = .systemColor(.secondarySystemGroupedBackground)
        toolbar.setSubviews(leftViews: [sortButton], rightViews: [filterButton])

        return toolbar
    }

    func createTopBannerView() -> TopBannerView {
        let title: String
        let infoText: String

        title = NSLocalizedString("Limited editing available",
                                  comment: "The title of the Work In Progress top banner on the Products tab")
        infoText = NSLocalizedString("We’ve added editing functionality to simple products. Keep an eye out for more options soon!",
                                     comment: "The info of the Work In Progress top banner on the Products tab")

        let viewModel = TopBannerViewModel(title: title,
                                           infoText: infoText,
                                           icon: .workInProgressBanner) { [weak self] in
                                            self?.tableView.updateHeaderHeight()
        }
        let topBannerView = TopBannerView(viewModel: viewModel)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        return topBannerView
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
    func updateResultsController(siteID: Int64) {
        resultsController = createResultsController(siteID: siteID)
        configureResultsController(resultsController) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    func createResultsController(siteID: Int64) -> ResultsController<StorageProduct> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)

        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                 matching: predicate,
                                                 sortOrder: sortOrder)
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
        cell.update(viewModel: viewModel, imageService: imageService)

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension ProductsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? Constants.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        ServiceLocator.analytics.track(.productListProductTapped)

        let product = resultsController.object(at: indexPath)

        let isEditProductsFeatureFlagOn = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.editProducts)
        didSelectProduct(product: product, isEditProductsEnabled: isEditProductsFeatureFlagOn)
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
    func didSelectProduct(product: Product, isEditProductsEnabled: Bool) {
        let currencyCode = CurrencySettings.shared.currencyCode
        let currency = CurrencySettings.shared.symbol(from: currencyCode)
        let viewController: UIViewController
        if product.productType == .simple && isEditProductsEnabled {
            viewController = ProductFormViewController(product: product, currency: currency)
            // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
            viewController.hidesBottomBarWhenPushed = true
        } else {
            let viewModel = ProductDetailsViewModel(product: product, currency: currency)
            viewController = ProductDetailsViewController(viewModel: viewModel)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - Actions
//
private extension ProductsViewController {
    @objc private func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.productListPulledToRefresh)

        syncingCoordinator.resynchronize {
            sender.endRefreshing()
        }
    }

    @objc func sortButtonTapped(button: UIButton) {
        let viewProperties = ListSelectorViewProperties(navigationBarTitle: "Sort by")
        let dataSource = ProductSortOptionListSelectorDataSource(selected: sortOrder)
        let sortOptionListViewController = ListSelectorViewController(viewProperties: viewProperties, dataSource: dataSource) { [weak self] selectedSortOrder in
            defer {
                self?.dismiss(animated: true, completion: nil)
            }

            guard let selectedSortOrder = selectedSortOrder else {
                return
            }
            self?.sortOrder = selectedSortOrder
        }

        let bottomSheet = BottomSheetViewController(childViewController: sortOptionListViewController)
        bottomSheet.show(from: self, sourceView: button, arrowDirections: .up)
    }

    @objc func filterButtonTapped() {
        // TODO-2037: implement filtering products
    }
}

// MARK: - Placeholders
//
private extension ProductsViewController {

    /// Renders the Placeholder Orders: For safety reasons, we'll also halt ResultsController <> UITableView glue.
    ///
    func displayPlaceholderProducts() {
        let options = GhostOptions(reuseIdentifier: ProductsTabProductTableViewCell.reuseIdentifier, rowsPerSection: Constants.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options,
        style: .wooDefaultGhostStyle)

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
        overlayView.messageImage = .emptyProductsImage
        overlayView.messageText = NSLocalizedString("No products yet",
                                                    comment: "The text on the placeholder overlay when there are no products on the Products tab")
        overlayView.actionVisible = false

        // Pins the overlay view to the bottom of the top banner view.
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: topStackView.bottomAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)? = nil) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            onCompletion?(false)
            return
        }

        transitionToSyncingState(pageNumber: pageNumber)

        let action = ProductAction
            .synchronizeProducts(siteID: siteID,
                                 pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 sortOrder: sortOrder) { [weak self] error in
                                    guard let self = self else {
                                        return
                                    }

                                    if let error = error {
                                        ServiceLocator.analytics.track(.productListLoadError, withError: error)
                                        DDLogError("⛔️ Error synchronizing products: \(error)")
                                        self.displaySyncingErrorNotice(pageNumber: pageNumber, pageSize: pageSize)
                                    } else {
                                        ServiceLocator.analytics.track(.productListLoaded)
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

    func didEnter(state: PaginatedListViewControllerState) {
        switch state {
        case .noResultsPlaceholder:
            displayNoResultsOverlay()
        case .syncing(let pageNumber):
            if pageNumber == SyncingCoordinator.Defaults.pageFirstIndex {
                displayPlaceholderProducts()
            } else {
                ensureFooterSpinnerIsStarted()
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

    func transitionToSyncingState(pageNumber: Int) {
        stateCoordinator.transitionToSyncingState(pageNumber: pageNumber)
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
private extension ProductsViewController {

    enum Constants {
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
        static let headerDefaultHeight = CGFloat(130)
        static let headerContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let toolbarButtonInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }
}
