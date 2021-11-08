import UIKit
import WordPressUI
import Yosemite
import SafariServices.SFSafariViewController

import class AutomatticTracks.CrashLogging

/// Shows a list of products with pull to refresh and infinite scroll
/// TODO: it will be good to have unit tests for this, introducing a `ViewModel`
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

    /// Empty Footer Placeholder. Replaces spinner view and allows footer to collapse and be completely hidden.
    ///
    private lazy var footerEmptyView = UIView(frame: .zero)

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
        configureResultsController(resultsController, onReload: { [weak self] in
            self?.reloadTableAndView()
        })
        return resultsController
    }()

    private var sortOrder: ProductsSortOrder = .default {
        didSet {
            if sortOrder != oldValue {
                updateLocalProductSettings(sort: sortOrder,
                                           filters: filters)
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
                updateLocalProductSettings(sort: sortOrder,
                                           filters: filters)
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

    /// Set when an empty state view controller is displayed.
    ///
    private var emptyStateViewController: UIViewController?

    private let siteID: Int64

    /// Set when sync fails, and used to display an error loading data banner
    ///
    private var hasErrorLoadingData: Bool = false

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
        configureToolBarView()
        configureSyncingCoordinator()
        registerTableViewCells()

        showTopBannerViewIfNeeded()

        /// We sync the local product settings for configuring local sorting and filtering.
        /// If there are some info stored when this screen is loaded, the data will be updated using the stored sort/filters.
        /// If no info are stored (so there is a failure), we resynchronize the syncingCoordinator for updating the screen using the default sort/filters.
        ///
        syncLocalProductsSettings { [weak self] (result) in
            if result.isFailure {
                self?.syncingCoordinator.resynchronize()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if AppRatingManager.shared.shouldPromptForAppReview() {
            displayRatingPrompt()
        }

        // Fix any incomplete animation of the refresh control
        // when switching tabs mid-animation
        refreshControl.resetAnimation(in: tableView) { [unowned self] in
            // ghost animation is also removed after switching tabs
            // show make sure it's displayed again
            self.removePlaceholderProducts()
            self.displayPlaceholderProducts()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateTableHeaderViewHeight()
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }
}

// MARK: - Navigation Bar Actions
//
private extension ProductsViewController {
    @IBAction func displaySearchProducts() {
        ServiceLocator.analytics.track(.productListMenuSearchTapped)

        let searchViewController = SearchViewController(storeID: siteID,
                                                        command: ProductSearchUICommand(siteID: siteID),
                                                        cellType: ProductsTabProductTableViewCell.self,
                                                        cellSeparator: .none)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }

    @objc func scanProducts() {
        // TODO-2407: scan barcodes for products
    }

    @objc func addProduct(_ sender: UIBarButtonItem) {
        addProduct(sourceBarButtonItem: sender)
    }

    func addProduct(sourceBarButtonItem: UIBarButtonItem? = nil, sourceView: UIView? = nil) {
        guard let navigationController = navigationController, sourceBarButtonItem != nil || sourceView != nil else {
            return
        }

        ServiceLocator.analytics.track(.productListAddProductTapped)

        let coordinatingController: AddProductCoordinator
        if let sourceBarButtonItem = sourceBarButtonItem {
            coordinatingController = AddProductCoordinator(siteID: siteID,
                                                           sourceBarButtonItem: sourceBarButtonItem,
                                                           sourceNavigationController: navigationController)
        } else if let sourceView = sourceView {
            coordinatingController = AddProductCoordinator(siteID: siteID,
                                                           sourceView: sourceView,
                                                           sourceNavigationController: navigationController)
        } else {
            fatalError("No source view for adding a product")
        }
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

        configureNavigationBarRightButtonItems()
    }

    func configureNavigationBarRightButtonItems() {
        var rightBarButtonItems = [UIBarButtonItem]()
        let buttonItem: UIBarButtonItem = {
            let button = UIBarButtonItem(image: .plusBarButtonItemImage,
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

        let searchItem: UIBarButtonItem = {
            let button = UIBarButtonItem(image: .searchBarButtonItemImage,
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
        rightBarButtonItems.append(searchItem)

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
        tableView.tableFooterView = footerSpinnerView
        tableView.separatorStyle = .none

        // Adds the refresh control to table view manually so that the refresh control always appears below the navigation bar title in
        // large or normal size to be consistent with Dashboard and Orders tab with large titles workaround.
        // If we do `tableView.refreshControl = refreshControl`, the refresh control appears in the navigation bar when large title is shown.
        tableView.addSubview(refreshControl)

        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: Int(Constants.headerDefaultHeight)))
        headerContainer.backgroundColor = .systemColor(.secondarySystemGroupedBackground)
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

        // Updates products tab state after table view is configured, otherwise the initial state is always showing results.
        stateCoordinator.transitionToResultsUpdatedState(hasData: !isEmpty)
    }

    /// Configure toolbar view by number of products
    ///
    func configureToolBarView() {
        showOrHideToolBar()
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

    /// Show or hide the toolbar based on number of products
    /// if there is any filter applied, toolbar must be always visible
    /// If there is 0 products, toolbar will be hidden
    /// if there is 1 or more products, toolbar will be visible
    ///
    func showOrHideToolBar() {
        toolbar.isHidden = filters.numberOfActiveFilters == 0 ? isEmpty : false
    }
}

// MARK: - Updates
//
private extension ProductsViewController {
    /// Fetches products feedback visibility from AppSettingsStore and update products top banner accordingly.
    /// If there is an error loading products data, an error banner replaces the products top banner.
    ///
    func showTopBannerViewIfNeeded() {
        guard !hasErrorLoadingData else {
            requestAndShowErrorTopBannerView()
            return
        }

        let action = AppSettingsAction.loadFeedbackVisibility(type: .productsVariations) { [weak self] result in
            switch result {
            case .success(let visible):
                if visible {
                    self?.requestAndShowNewTopBannerView(for: .variations)
                } else {
                    self?.hideTopBannerView()
                }
            case.failure(let error):
                self?.hideTopBannerView()
                ServiceLocator.crashLogging.logError(error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Request a new product banner from `ProductsTopBannerFactory` and wire actionButtons actions
    ///
    func requestAndShowNewTopBannerView(for bannerType: ProductsTopBannerFactory.BannerType) {
        let isExpanded = topBannerView?.isExpanded ?? false
        ProductsTopBannerFactory.topBanner(isExpanded: isExpanded,
                                           type: bannerType,
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

    /// Request a new error loading data banner from `ErrorTopBannerFactory` and display it in the table header
    ///
    func requestAndShowErrorTopBannerView() {
        let errorBanner = ErrorTopBannerFactory.createTopBanner(
            isExpanded: false,
            expandedStateChangeHandler: { [weak self] in
                self?.tableView.updateHeaderHeight()
            },
            onTroubleshootButtonPressed: { [weak self] in
                let safariViewController = SFSafariViewController(url: WooConstants.URLs.troubleshootErrorLoadingData.asURL())
                self?.present(safariViewController, animated: true, completion: nil)
            },
            onContactSupportButtonPressed: { [weak self] in
                guard let self = self else { return }
                ZendeskManager.shared.showNewRequestIfPossible(from: self, with: nil)
            })
        topBannerContainerView.updateSubview(errorBanner)
        topBannerView = errorBanner
        updateTableHeaderViewHeight()
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

    /// Configure resultController.
    /// Assign closures and start performBatch
    ///
    func configureResultsController(_ resultsController: ResultsController<StorageProduct>, onReload: @escaping () -> Void) {
        setClosuresToResultController(resultsController, onReload: onReload)

        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }

        tableView.reloadData()
    }

    /// Set closure  to methods `onDidChangeContent` and `onDidResetContent
    ///
    func setClosuresToResultController(_ resultsController: ResultsController<StorageProduct>, onReload: @escaping () -> Void) {
        resultsController.onDidChangeContent = {
            onReload()
        }

        resultsController.onDidResetContent = {
            onReload()
        }
    }

    /// Manages view components and reload tableview
    ///
    func reloadTableAndView() {
        showOrHideToolBar()
        addOrRemoveOverlay()
        tableView.reloadData()
    }

    /// Add or remove the overlay based on number of products
    /// If there is 0 products, overlay will be added
    /// if there is 1 or more products, toolbar will be removed
    ///
    func addOrRemoveOverlay() {
        guard isEmpty else {
            removeAllOverlays()
            return
        }
        displayNoResultsOverlay()
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
        let command = ProductsSortOrderBottomSheetListSelectorCommand(selected: sortOrder) { [weak self] selectedSortOrder in
            self?.dismiss(animated: true, completion: nil)
            guard let selectedSortOrder = selectedSortOrder as ProductsSortOrder? else {
                    return
                }
            self?.sortOrder = selectedSortOrder
        }
        let sortOrderListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties,
                                                                      command: command)

        sortOrderListPresenter.show(from: self, sourceView: sender, arrowDirections: .up)
    }

    @objc func filterButtonTapped() {
        ServiceLocator.analytics.track(.productListViewFilterOptionsTapped)
        let viewModel = FilterProductListViewModel(filters: filters, siteID: siteID)
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

    func clearFilter(sourceBarButtonItem: UIBarButtonItem? = nil, sourceView: UIView? = nil) {
        ServiceLocator.analytics.track(.productListClearFiltersTapped)
        self.filters = FilterProductListViewModel.Filters()
    }

    /// Presents products survey
    ///
    func presentProductsFeedback() {
        // Present survey
        let navigationController = SurveyCoordinatingController(survey: .productsVariationsFeedback)
        present(navigationController, animated: true, completion: nil)
    }

    /// Mark feedback request as dismissed and update banner visibility
    ///
    func dismissProductsBanner() {
        let action = AppSettingsAction.updateFeedbackStatus(type: .productsVariations,
                                                            status: .dismissed) { [weak self] result in
            if let error = result.failure {
                ServiceLocator.crashLogging.logError(error)
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
        // Assign again the original closure
        setClosuresToResultController(resultsController, onReload: { [weak self] in
            self?.reloadTableAndView()
        })
        tableView.reloadData()
    }

    /// Displays the overlay when there are no results.
    ///
    func displayNoResultsOverlay() {
        let emptyStateViewController = EmptyStateViewController(style: .list)
        let config = filters.numberOfActiveFilters == 0 ? createNoProductsConfig() : createNoProductsMatchFilterConfig()
        displayEmptyStateViewController(emptyStateViewController)
        emptyStateViewController.configure(config)
    }

    /// Creates EmptyStateViewController.Config for no products empty view
    ///
    func createNoProductsConfig() ->  EmptyStateViewController.Config {
        let message = NSLocalizedString("No products yet",
                                        comment: "The text on the placeholder overlay when there are no products on the Products tab")
        let details = NSLocalizedString("Start selling today by adding your first product to the store.",
                                        comment: "The details on the placeholder overlay when there are no products on the Products tab")
        let buttonTitle = NSLocalizedString("Add Product",
                                            comment: "Action to add product on the placeholder overlay when there are no products on the Products tab")
        return EmptyStateViewController.Config.withButton(
            message: .init(string: message),
            image: .emptyProductsTabImage,
            details: details,
            buttonTitle: buttonTitle) { [weak self] button in
            self?.addProduct(sourceView: button)
        }
    }

    /// Creates EmptyStateViewController.Config for no products match the filter empty view
    ///
    func createNoProductsMatchFilterConfig() ->  EmptyStateViewController.Config {
        let message = NSLocalizedString("No matching products found",
                                        comment: "The text on the placeholder overlay when no products match the filter on the Products tab")
        let buttonTitle = NSLocalizedString("Clear Filters",
                                            comment: "Action to add product on the placeholder overlay when no products match the filter on the Products tab")
        return EmptyStateViewController.Config.withButton(
            message: .init(string: message),
            image: .emptyProductsTabImage,
            details: "",
            buttonTitle: buttonTitle) { [weak self] button in
                self?.clearFilter(sourceView: button)
        }
    }

    /// Shows the EmptyStateViewController as a child view controller.
    ///
    func displayEmptyStateViewController(_ emptyStateViewController: UIViewController) {
        self.emptyStateViewController = emptyStateViewController
        addChild(emptyStateViewController)

        emptyStateViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateViewController.view)

        NSLayoutConstraint.activate([
            emptyStateViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateViewController.view.topAnchor.constraint(equalTo: topStackView.bottomAnchor),
            emptyStateViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        emptyStateViewController.didMove(toParent: self)
    }

    /// Removes EmptyStateViewController child view controller if applicable.
    ///
    func removeAllOverlays() {
        guard let emptyStateViewController = emptyStateViewController, emptyStateViewController.parent == self else {
            return
        }

        emptyStateViewController.willMove(toParent: nil)
        emptyStateViewController.view.removeFromSuperview()
        emptyStateViewController.removeFromParent()
        self.emptyStateViewController = nil
    }
}

// MARK: - Sync'ing Helpers
//
extension ProductsViewController: SyncingCoordinatorDelegate {

    /// Synchronizes the Products for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String? = nil, onCompletion: ((Bool) -> Void)? = nil) {
        transitionToSyncingState(pageNumber: pageNumber)
        hasErrorLoadingData = false

        let action = ProductAction
            .synchronizeProducts(siteID: siteID,
                                 pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 stockStatus: filters.stockStatus,
                                 productStatus: filters.productStatus,
                                 productType: filters.productType,
                                 productCategory: filters.productCategory,
                                 sortOrder: sortOrder) { [weak self] result in
                                    guard let self = self else {
                                        return
                                    }

                                    switch result {
                                    case .failure(let error):
                                        ServiceLocator.analytics.track(.productListLoadError, withError: error)
                                        DDLogError("⛔️ Error synchronizing products: \(error)")
                                        self.hasErrorLoadingData = true
                                    case .success:
                                        ServiceLocator.analytics.track(.productListLoaded)
                                    }

                                    self.transitionToResultsUpdatedState()
                                    onCompletion?(result.isSuccess)
        }

        ServiceLocator.stores.dispatch(action)
    }

    /// Update local Products Settings (eg. sort order or filters stored in Products settings)
    ///
    private func updateLocalProductSettings(sort: ProductsSortOrder? = nil,
                                            filters: FilterProductListViewModel.Filters) {
        let action = AppSettingsAction.upsertProductsSettings(siteID: siteID,
                                                              sort: sort?.rawValue,
                                                              stockStatusFilter: filters.stockStatus,
                                                              productStatusFilter: filters.productStatus,
                                                              productTypeFilter: filters.productType,
                                                              productCategoryFilter: filters.productCategory) { (error) in
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Fetch local Products Settings (eg.  sort order or filters stored in Products settings)
    ///
    private func syncLocalProductsSettings(onCompletion: @escaping (Result<StoredProductSettings.Setting, Error>) -> Void) {
        let action = AppSettingsAction.loadProductsSettings(siteID: siteID) { [weak self] (result) in
            switch result {
            case .success(let settings):
                if let sort = settings.sort {
                    self?.sortOrder = ProductsSortOrder(rawValue: sort) ?? .default
                }
                self?.filters = FilterProductListViewModel.Filters(stockStatus: settings.stockStatusFilter,
                                                                   productStatus: settings.productStatusFilter,
                                                                   productType: settings.productTypeFilter,
                                                                   productCategory: settings.productCategoryFilter,
                                                                   numberOfActiveFilters: settings.numberOfActiveFilters())
            case .failure:
                break
            }
            onCompletion(result)
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
            // Remove top banner when sync starts
            hideTopBannerView()
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
            showTopBannerViewIfNeeded()
            showOrHideToolBar()
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
