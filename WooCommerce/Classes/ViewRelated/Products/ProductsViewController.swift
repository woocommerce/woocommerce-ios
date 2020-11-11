import UIKit
import WordPressUI
import Yosemite

import class AutomatticTracks.CrashLogging

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
        let subviews = [topBannerContainerView, toolbar]
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.spacing = Constants.headerViewSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /// Top toolbar that shows the sort and filter CTAs.
    ///
    private lazy var toolbar: UIView = {
        return createToolbar()
    }()

    /// The filter CTA in the top toolbar.
    private lazy var filterButton: UIButton = UIButton(frame: .zero)

    /// Container of the top banner that shows that the Products feature is still work in progress.
    ///
    private lazy var topBannerContainerView: SwappableSubviewContainerView = SwappableSubviewContainerView()

    /// Top banner that shows that the Products feature is still work in progress.
    ///
    private var topBannerView: TopBannerView?

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Products in sync.
    ///
    private lazy var resultsController: ResultsController<StorageProduct> = {
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

                /// Reload data because `updateSortOrder` generates a new `predicate` which calls `performFetch`
                tableView.reloadData()

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

    private var filters: FilterProductListViewModel.Filters = FilterProductListViewModel.Filters() {
        didSet {
            if filters != oldValue {
                updateFilterButtonTitle(filters: filters)

                resultsController.updatePredicate(siteID: siteID,
                                                  stockStatus: filters.stockStatus,
                                                  productStatus: filters.productStatus,
                                                  productType: filters.productType)

                /// Reload because `updatePredicate` calls `performFetch` when creating a new predicate
                tableView.reloadData()

                syncingCoordinator.resynchronize {}
            }
        }
    }

    private let siteID: Int64

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View Lifecycle

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)

        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureTableView()
        configureSyncingCoordinator()
        registerTableViewCells()

        updateTopBannerView()

        syncingCoordinator.resynchronize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if AppRatingManager.shared.shouldPromptForAppReview() {
            displayRatingPrompt()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateTableHeaderViewHeight()
    }
}

// MARK: - Navigation Bar Actions
//
private extension ProductsViewController {
    @IBAction func displaySearchProducts() {
        ServiceLocator.analytics.track(.productListMenuSearchTapped)

        let searchViewController = SearchViewController(storeID: siteID,
                                                        command: ProductSearchUICommand(siteID: siteID),
                                                        cellType: ProductsTabProductTableViewCell.self)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }

    @objc func scanProducts() {
        // TODO-2407: scan barcodes for products
    }

    @objc func addProduct(_ sender: UIBarButtonItem) {
        guard let navigationController = navigationController else {
            return
        }

        ServiceLocator.analytics.track(.productListAddProductTapped)

        let coordinatingController = AddProductCoordinator(siteID: siteID, sourceView: sender, sourceNavigationController: navigationController)
        coordinatingController.start()
    }
}

// MARK: - View Configuration
//
private extension ProductsViewController {

    /// Set the title.
    ///
    func configureNavigationBar() {
        navigationItem.title = NSLocalizedString(
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

        configureNavigationBarRightButtonItems()
    }

    func configureNavigationBarRightButtonItems() {
        var rightBarButtonItems = [UIBarButtonItem]()
        let buttonItem: UIBarButtonItem = {
            let button = UIBarButtonItem(image: .plusImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(addProduct(_:)))
            button.accessibilityTraits = .button
            button.accessibilityLabel = NSLocalizedString("Add a product", comment: "The action to add a product")
            return button
        }()
        rightBarButtonItems.append(buttonItem)

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.barcodeScanner) {
            let buttonItem: UIBarButtonItem = {
                let button = UIBarButtonItem(image: .scanImage,
                                             style: .plain,
                                             target: self,
                                             action: #selector(scanProducts))
                button.accessibilityTraits = .button
                button.accessibilityLabel = NSLocalizedString("Scan products", comment: "Scan Products")
                button.accessibilityHint = NSLocalizedString(
                    "Scans barcodes that are associated with a product SKU for stock management.",
                    comment: "VoiceOver accessibility hint, informing the user the button can be used to scan products."
                )

                return button
            }()
            rightBarButtonItems.append(buttonItem)
        }

        navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTabBarItem() {
        tabBarItem.title = NSLocalizedString("Products", comment: "Title of the Products tab — plural form of Product")
        tabBarItem.image = .productImage
        tabBarItem.accessibilityIdentifier = "tab-bar-products-item"
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
        sortButton.addTarget(self, action: #selector(sortButtonTapped(sender:)), for: .touchUpInside)

        let filterTitle = NSLocalizedString("Filter", comment: "Title of the toolbar button to filter products by different attributes.")
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

    /// Setup: Sync'ing Coordinator
    ///
    func configureSyncingCoordinator() {
        syncingCoordinator.delegate = self
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        tableView.register(ProductsTabProductTableViewCell.self)
    }
}

// MARK: - Updates
//
private extension ProductsViewController {
    /// Fetches products feedback visibility from AppSettingsStore and update products top banner accordingly
    ///
    func updateTopBannerView() {
        let action = AppSettingsAction.loadFeedbackVisibility(type: .productsM4) { [weak self] result in
            switch result {
            case .success(let visible):
                if visible {
                    self?.requestAndShowNewTopBannerView()
                } else {
                    self?.hideTopBannerView()
                }
            case.failure(let error):
                self?.hideTopBannerView()
                CrashLogging.logError(error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Request a new product banner from `ProductsTopBannerFactory` and wire actionButtons actions
    ///
    func requestAndShowNewTopBannerView() {
        let isExpanded = topBannerView?.isExpanded ?? false
        ProductsTopBannerFactory.topBanner(isExpanded: isExpanded,
                                           expandedStateChangeHandler: { [weak self] in
            self?.updateTableHeaderViewHeight()
        }, onGiveFeedbackButtonPressed: { [weak self] in
            self?.presentProductsFeedback()
        }, onDismissButtonPressed: { [weak self] in
            self?.dismissProductsBanner()
        }, onCompletion: { [weak self] topBannerView in
            self?.topBannerContainerView.updateSubview(topBannerView)
            self?.topBannerView = topBannerView
            self?.updateTableHeaderViewHeight()
        })
    }

    func hideTopBannerView() {
        topBannerView?.removeFromSuperview()
        topBannerView = nil
        updateTableHeaderViewHeight()
    }

    /// Updates table header view with the correct spacing / edges depending if `topBannerContainerView` is empty or not.
    ///
    func updateTableHeaderViewHeight() {
        topStackView.spacing = topBannerContainerView.subviews.isNotEmpty ? Constants.headerViewSpacing : 0
        tableView.updateHeaderHeight()
    }

    func createResultsController(siteID: Int64) -> ResultsController<StorageProduct> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate.createProductPredicate(siteID: siteID,
                                                           stockStatus: filters.stockStatus,
                                                           productStatus: filters.productStatus,
                                                           productType: filters.productType)

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

        do {
            try resultsController.performFetch()
        } catch {
            CrashLogging.logError(error)
        }

        tableView.reloadData()
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
        let cell = tableView.dequeueReusableCell(ProductsTabProductTableViewCell.self, for: indexPath)

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

        didSelectProduct(product: product)
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
    func didSelectProduct(product: Product) {
        ProductDetailsFactory.productDetails(product: product, presentationStyle: .navigationStack, forceReadOnly: false) { [weak self] viewController in
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
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

    @objc func sortButtonTapped(sender: UIButton) {
        ServiceLocator.analytics.track(.productListViewSortingOptionsTapped)
        let title = NSLocalizedString("Sort by",
                                      comment: "Message title for sort products action bottom sheet")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title)
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: sortOrder)
        let sortOrderListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties,
                                                                      command: command) { [weak self] selectedSortOrder in
                                                                        defer {
                                                                            self?.dismiss(animated: true, completion: nil)
                                                                        }

                                                                        guard let selectedSortOrder = selectedSortOrder else {
                                                                            return
                                                                        }
                                                                        self?.sortOrder = selectedSortOrder
         ServiceLocator.analytics.track(.productSortingListOptionSelected, withProperties: ["order": selectedSortOrder.analyticsDescription])
        }
        sortOrderListPresenter.show(from: self, sourceView: sender, arrowDirections: .up)
    }

    @objc func filterButtonTapped() {
        ServiceLocator.analytics.track(.productListViewFilterOptionsTapped)
        let viewModel = FilterProductListViewModel(filters: filters)
        let filterProductListViewController = FilterListViewController(viewModel: viewModel, onFilterAction: { [weak self] filters in
            ServiceLocator.analytics.track(.productFilterListShowProductsButtonTapped, withProperties: ["filters": filters.analyticsDescription])
            self?.filters = filters
        }, onClearAction: {
            ServiceLocator.analytics.track(.productFilterListClearMenuButtonTapped)
        }, onDismissAction: {
            ServiceLocator.analytics.track(.productFilterListDismissButtonTapped)
        })
        present(filterProductListViewController, animated: true, completion: nil)
    }

    /// Presents products survey and mark feedback as given to update banner visibility
    ///
    func presentProductsFeedback() {
        // Present survey
        let navigationController = SurveyCoordinatingController(survey: .productsM4Feedback)
        present(navigationController, animated: true) { [weak self] in

            // Mark survey as given and update top banner view
            let action = AppSettingsAction.updateFeedbackStatus(type: .productsM4, status: .given(Date())) { result in
                if let error = result.failure {
                    CrashLogging.logError(error)
                }
                self?.hideTopBannerView()
            }
            ServiceLocator.stores.dispatch(action)
        }
    }

    /// Mark feedback request as dismissed and update banner visibility
    ///
    func dismissProductsBanner() {
        let action = AppSettingsAction.updateFeedbackStatus(type: .productsM4, status: .dismissed) { [weak self] result in
            if let error = result.failure {
                CrashLogging.logError(error)
            }
            self?.hideTopBannerView()
        }
        ServiceLocator.stores.dispatch(action)
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
        transitionToSyncingState(pageNumber: pageNumber)

        let action = ProductAction
            .synchronizeProducts(siteID: siteID,
                                 pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 stockStatus: filters.stockStatus,
                                 productStatus: filters.productStatus,
                                 productType: filters.productType,
                                 sortOrder: sortOrder) { [weak self] result in
                                    guard let self = self else {
                                        return
                                    }

                                    switch result {
                                    case .failure(let error):
                                        ServiceLocator.analytics.track(.productListLoadError, withError: error)
                                        DDLogError("⛔️ Error synchronizing products: \(error)")
                                        self.displaySyncingErrorNotice(pageNumber: pageNumber, pageSize: pageSize)
                                    case .success:
                                        ServiceLocator.analytics.track(.productListLoaded)
                                    }

                                    self.transitionToResultsUpdatedState()
                                    onCompletion?(result.isSuccess)
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

// MARK: - Filter UI Helpers
//
private extension ProductsViewController {
    func updateFilterButtonTitle(filters: FilterProductListViewModel.Filters) {
        let activeFilterCount = filters.numberOfActiveFilters

        let titleWithoutActiveFilters =
            NSLocalizedString("Filter", comment: "Title of the toolbar button to filter products without any filters applied.")
        let titleFormatWithActiveFilters =
            NSLocalizedString("Filter (%ld)", comment: "Title of the toolbar button to filter products with filters applied.")

        let title = activeFilterCount > 0 ?
            String.localizedStringWithFormat(titleFormatWithActiveFilters, activeFilterCount): titleWithoutActiveFilters

        filterButton.setTitle(title, for: .normal)
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
        static let headerViewSpacing = CGFloat(8)
        static let estimatedRowHeight = CGFloat(86)
        static let placeholderRowsPerSection = [3]
        static let headerDefaultHeight = CGFloat(130)
        static let headerContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let toolbarButtonInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }
}
