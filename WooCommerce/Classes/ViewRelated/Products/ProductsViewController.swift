import Experiments
import UIKit
import SwiftUI
import WordPressUI
import Yosemite
import Combine

import class AutomatticTracks.CrashLogging

/// Shows a list of products with pull to refresh and infinite scroll
/// TODO: it will be good to have unit tests for this, introducing a `ViewModel`
///
final class ProductsViewController: UIViewController, GhostableViewController {
    enum NavigationContentType {
        case productForm(product: Product)
        case addProduct(sourceView: AddProductCoordinator.SourceView, isFirstProduct: Bool)
        case search
    }

    let viewModel: ProductListViewModel

    /// The coordinator for sharing products
    ///
    private var shareProductCoordinator: ShareProductCoordinator?

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    private var barcodeScannerCoordinator: ProductSKUBarcodeScannerCoordinator?

    lazy var ghostTableViewController = GhostTableViewController(options: GhostTableViewOptions(sectionHeaderVerticalSpace: .medium,
                                                                                                cellClass: ProductsTabProductTableViewCell.self,
                                                                                                rowsPerSection: Constants.placeholderRowsPerSection,
                                                                                                estimatedRowHeight: Constants.estimatedRowHeight,
                                                                                                separatorStyle: .none,
                                                                                                isScrollEnabled: false))

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
        let subviews = [topBannerContainerView]
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.spacing = Constants.headerViewSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /// The button in the navigation bar to add a product
    ///
    private lazy var addProductButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: .plusBarButtonItemImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(addProduct(_:)))
        button.accessibilityTraits = .button
        button.accessibilityLabel = NSLocalizedString("Add a product", comment: "The action to add a product")
        button.accessibilityIdentifier = "product-add-button"
        return button
    }()

    /// Top toolbar that shows the sort and filter CTAs.
    ///
    @IBOutlet private weak var toolbar: ToolbarView!
    @IBOutlet private weak var toolbarBottomSeparator: UIView!
    @IBOutlet private weak var toolbarBottomSeparatorHeightConstraint: NSLayoutConstraint!

    // Used to trick the navigation bar for large title (ref: issue 3 in p91TBi-45c-p2).
    private let hiddenScrollView = UIScrollView()

    /// The filter CTA in the top toolbar.
    private lazy var filterButton: UIButton = UIButton(frame: .zero)

    /// The bulk edit CTA in the navbar.
    private lazy var bulkEditButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: Localization.bulkEditingToolbarButtonTitle,
                                     style: .plain,
                                     target: self,
                                     action: #selector(openBulkEditingOptions(sender:)))
        button.isEnabled = false
        return button
    }()

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
            guard let self else { return }
            self.reloadTableAndView()
        })
        return resultsController
    }()

    private var selectedProductListener: EntityListener<Product>?

    private var sortOrder: ProductsSortOrder = .default {
        didSet {
            if sortOrder != oldValue {
                updateLocalProductSettings(sort: sortOrder,
                                           filters: filters)
                resultsController.updateSortOrder(sortOrder)

                /// Reload data because `updateSortOrder` generates a new `predicate` which calls `performFetch`
                tableView.reloadData()

                paginationTracker.resync()
            }
        }
    }

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    /// Indicates if there are no results onscreen.
    ///
    private var isEmpty: Bool {
        resultsController.isEmpty
    }

    /// Supports infinite scroll.
    private let scrollWatcher = ScrollWatcher()
    private let paginationTracker: PaginationTracker
    private var scrollWatcherSubscription: AnyCancellable?

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
            if filters != oldValue ||
                categoryHasChangedRemotely {
                updateLocalProductSettings(sort: sortOrder,
                                           filters: filters)
                updateFilterButtonTitle(filters: filters)

                resultsController.updatePredicate(siteID: siteID,
                                                  stockStatus: filters.stockStatus,
                                                  productStatus: filters.productStatus,
                                                  productType: filters.promotableProductType?.productType)

                /// Reload because `updatePredicate` calls `performFetch` when creating a new predicate
                tableView.reloadData()

                paginationTracker.resync()
            }
        }
    }

    /// Set to `true` when a category is applied to the product filters and the value has changed after a remote sync.
    private var categoryHasChangedRemotely: Bool = false

    /// Set when an empty state view controller is displayed.
    ///
    private var emptyStateViewController: UIViewController?

    private let siteID: Int64

    /// Set when sync fails, and used to display an error loading data banner
    ///
    @Published private var dataLoadingError: Error?

    /// Store plan banner presentation handler.
    ///
    private var storePlanBannerPresenter: StorePlanBannerPresenter?

    private var subscriptions: Set<AnyCancellable> = []

    private var addProductCoordinator: AddProductCoordinator?

    /// Tracks if the swipe actions have been glanced to the user.
    ///
    private var swipeActionsGlanced = false

    private let isSplitViewEnabled: Bool
    private let navigateToContent: (NavigationContentType) -> Void
    private let selectedProduct: AnyPublisher<Product?, Never>
    private let onTableViewEditingEnd: PassthroughSubject<Void, Never> = .init()
    let onDataReloaded: PassthroughSubject<Void, Never> = .init()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View Lifecycle

    init(siteID: Int64,
         selectedProduct: AnyPublisher<Product?, Never>,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         navigateToContent: @escaping (NavigationContentType) -> Void) {
        self.siteID = siteID
        self.viewModel = .init(siteID: siteID, stores: ServiceLocator.stores)
        self.selectedProduct = selectedProduct
        self.isSplitViewEnabled = featureFlagService.isFeatureFlagEnabled(.splitViewInProductsTab)
        self.navigateToContent = navigateToContent
        self.paginationTracker = PaginationTracker()
        super.init(nibName: type(of: self).nibName, bundle: nil)

        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registerUserActivity()

        configureNavigationBar()
        configureMainView()
        configureTableView()
        configureHiddenScrollView()
        configureToolbar()
        configureScrollWatcher()
        configurePaginationTracker()
        configureStorePlanBannerPresenter()
        registerTableViewCells()

        showTopBannerViewIfNeeded()
        syncProductsSettings()
        observeSelectedProductAndDataLoadedStateToUpdateSelectedRow()
        observeSelectedProductToAutoScrollWhenProductChanges()
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
            self.removeGhostContent()
            self.displayGhostContent(over: tableView)
        }

        navigationController?.navigationBar.removeShadow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        finishBulkEditing()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateTableHeaderViewHeight()
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }

    /// Selects the first product if one is available. Invoked when no product is selected when data is loaded in split view expanded mode.
    func selectFirstProductIfAvailable() {
        guard let firstProduct = resultsController.fetchedObjects.first else {
            return
        }
        didSelectProduct(product: firstProduct)
    }

    func startProductCreation() {
        addProduct(sourceBarButtonItem: addProductButton, isFirstProduct: false)
    }
}

// MARK: - Navigation Bar Actions
//
private extension ProductsViewController {
    @IBAction func displaySearchProducts() {
        ServiceLocator.analytics.track(.productListMenuSearchTapped)
        navigateToContent(.search)
    }

    @objc func scanProducts() {
        ServiceLocator.analytics.track(.productListProductBarcodeScanningTapped)

        guard let navigationController = navigationController else {
            return
        }

        self.configureLeftBarBarButtomItemAsScanningButtonIfApplicable()

        let productSKUBarcodeScannerCoordinator = ProductSKUBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                                                      onSKUBarcodeScanned: { [weak self] scannedBarcode in
            guard let self = self else { return }
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.BarcodeScanning.barcodeScanningSuccess(from: .productList))

            Task {
                self.navigationItem.configureLeftBarButtonItemAsLoader()

                do {
                    let scannedItem = try await self.viewModel.handleScannedBarcode(scannedBarcode)
                    self.present(UIHostingController(rootView: UpdateProductInventoryView(inventoryItem: scannedItem.inventoryItem,
                                                                                          siteID: self.viewModel.siteID,
                                                                                          onUpdatedInventory: { newQuantity in
                        let noticeMessage = String.localizedStringWithFormat(Localization.updateInventoryNotice, newQuantity)
                        self.presentNotice(title: noticeMessage)
                    })), animated: true)
                } catch {
                    self.trackScannedItemSearchFailure(error)
                    let errorNotice = BarcodeSKUScannerErrorNoticeFactory.notice(for: error,
                                                                                 code: scannedBarcode,
                                                                                 actionHandler: {
                        self.scanProducts()
                    })
                    self.presentNotice(notice: errorNotice)
                }
                // Reset button state on finishing the task
                self.configureLeftBarBarButtomItemAsScanningButtonIfApplicable()
            }

        }, onPermissionsDenied: {
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.BarcodeScanning.barcodeScanningFailure(from: .productList,
                                                                                                           reason: .cameraAccessNotPermitted))
        })
        barcodeScannerCoordinator = productSKUBarcodeScannerCoordinator
        productSKUBarcodeScannerCoordinator.start()
    }

    @objc func addProduct(_ sender: UIBarButtonItem) {
        addProduct(sourceBarButtonItem: sender, isFirstProduct: false)
    }

    func addProduct(sourceBarButtonItem: UIBarButtonItem? = nil,
                    sourceView: UIView? = nil,
                    isFirstProduct: Bool) {
        let sourceView: AddProductCoordinator.SourceView? = {
            if let sourceBarButtonItem = sourceBarButtonItem {
                return .barButtonItem(sourceBarButtonItem)
            } else if let sourceView = sourceView {
                return .view(sourceView)
            } else {
                assertionFailure("No source view for adding a product")
                return nil
            }
        }()
        guard let sourceView else {
            return
        }
        guard isSplitViewEnabled else {
            guard let navigationController else {
                return
            }

            let source: AddProductCoordinator.Source = .productsTab
            let coordinatingController = AddProductCoordinator(siteID: siteID,
                                                               source: source,
                                                               sourceView: sourceView,
                                                               sourceNavigationController: navigationController,
                                                               isFirstProduct: isFirstProduct)

            coordinatingController.start()
            self.addProductCoordinator = coordinatingController
            return
        }

        navigateToContent(.addProduct(sourceView: sourceView, isFirstProduct: isFirstProduct))
    }
}

// MARK: - Analytics helpers
//
private extension ProductsViewController {
    func trackScannedItemSearchFailure(_ error: Error) {
        let source = WooAnalyticsEvent.BarcodeScanning.Source.scanToUpdateInventory.rawValue
        let errorDescription = error.localizedDescription
        let event = WooAnalyticsEvent.BarcodeScanning.productSearchViaSKUFailure(from: source, reason: errorDescription)
        ServiceLocator.analytics.track(event: event)
    }
}

// MARK: - Bulk Editing flows
//
private extension ProductsViewController {
    @objc func startBulkEditing() {
        tableView.setEditing(true, animated: true)

        // Disable pull-to-refresh while editing
        refreshControl.removeFromSuperview()

        configureNavigationBarForEditing()
        showOrHideToolbar()
    }

    @objc func finishBulkEditing() {
        guard let tableView, tableView.isEditing else {
            return
        }

        viewModel.deselectAll()
        tableView.setEditing(false, animated: true)
        onTableViewEditingEnd.send(())

        bulkEditButton.isEnabled = false

        // Enable pull-to-refresh
        tableView.addSubview(refreshControl)

        configureNavigationBar()
        showOrHideToolbar()
    }

    func updatedSelectedItems() {
        updateNavigationBarTitleForEditing()
        bulkEditButton.isEnabled = viewModel.bulkEditActionIsEnabled
    }

    @objc func selectAllProducts() {
        ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateSelectAllTapped())

        viewModel.selectProducts(resultsController.fetchedObjects)
        updatedSelectedItems()
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [], with: .none)
    }

    @objc func openBulkEditingOptions(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let updateStatus = UIAlertAction(title: Localization.bulkEditingStatusOption, style: .default) { [weak self] _ in
            self?.showStatusBulkEditingModal()
        }
        let updatePrice = UIAlertAction(title: Localization.bulkEditingPriceOption, style: .default) { [weak self] _ in
            self?.showPriceBulkEditingModal()
        }
        let cancelAction = UIAlertAction(title: Localization.cancel, style: .cancel)

        actionSheet.addAction(updateStatus)
        if !viewModel.onlyPriceIncompatibleProductsSelected {
            actionSheet.addAction(updatePrice)
        }
        actionSheet.addAction(cancelAction)

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = sender
        }

        present(actionSheet, animated: true)
    }

    func showStatusBulkEditingModal() {
        ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateRequested(field: .status, selectedProductsCount: viewModel.selectedProductsCount))

        let initialStatus = viewModel.commonStatusForSelectedProducts
        let command = ProductStatusSettingListSelectorCommand(selected: initialStatus)
        let listSelectorViewController = ListSelectorViewController(command: command) { _ in
            // view dismiss callback - no-op
        }
        listSelectorViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                                      target: self,
                                                                                      action: #selector(dismissModal))

        let applyButton = UIBarButtonItem(title: Localization.bulkEditingApply)
        applyButton.on(call: { [weak self] _ in
            self?.applyBulkEditingStatus(newStatus: command.selected, modalVC: listSelectorViewController)
        })
        command.$selected.sink { newStatus in
            if let newStatus, newStatus != initialStatus {
                applyButton.isEnabled = true
            } else {
                applyButton.isEnabled = false
            }
        }.store(in: &subscriptions)
        listSelectorViewController.navigationItem.rightBarButtonItem = applyButton

        present(WooNavigationController(rootViewController: listSelectorViewController), animated: true)
    }

    @objc func dismissModal() {
        dismiss(animated: true)
    }

    func applyBulkEditingStatus(newStatus: ProductStatus?, modalVC: UIViewController) {
        guard let newStatus else { return }

        ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateConfirmed(field: .status, selectedProductsCount: viewModel.selectedProductsCount))

        displayProductsSavingInProgressView(on: modalVC)
        viewModel.updateSelectedProducts(with: newStatus) { [weak self] result in
            guard let self else { return }

            self.dismiss(animated: true, completion: nil)
            switch result {
            case .success:
                self.finishBulkEditing()
                self.presentNotice(title: Localization.statusUpdatedNotice)
                ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateSuccess(field: .status))
            case .failure:
                self.presentNotice(title: Localization.updateErrorNotice)
                ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateFailure(field: .status))
            }
        }
    }

    func showPriceBulkEditingModal() {
        ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateRequested(field: .price, selectedProductsCount: viewModel.selectedProductsCount))

        let priceInputViewModel = PriceInputViewModel(productListViewModel: viewModel)
        let priceInputViewController = PriceInputViewController(viewModel: priceInputViewModel)
        priceInputViewModel.cancelClosure = { [weak self] in
            self?.dismissModal()
        }
        priceInputViewModel.applyClosure = { [weak self] newPrice in
            self?.applyBulkEditingPrice(newPrice: newPrice, modalVC: priceInputViewController)
        }
        present(WooNavigationController(rootViewController: priceInputViewController), animated: true)
    }

    func applyBulkEditingPrice(newPrice: String?, modalVC: UIViewController) {
        guard let newPrice else { return }

        ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateConfirmed(field: .price, selectedProductsCount: viewModel.selectedProductsCount))

        displayProductsSavingInProgressView(on: modalVC)
        viewModel.updateSelectedProducts(with: newPrice) { [weak self] result in
            guard let self else { return }

            self.dismiss(animated: true, completion: nil)
            switch result {
            case .success:
                self.finishBulkEditing()
                self.presentNotice(title: Localization.priceUpdatedNotice)
                ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateSuccess(field: .price))
            case .failure:
                self.presentNotice(title: Localization.updateErrorNotice)
                ServiceLocator.analytics.track(event: .ProductsList.bulkUpdateFailure(field: .price))
            }
        }
    }

    func displayProductsSavingInProgressView(on vc: UIViewController) {
        let viewProperties = InProgressViewProperties(title: Localization.productsSavingTitle, message: Localization.productsSavingMessage)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .fullScreen

        vc.present(inProgressViewController, animated: true, completion: nil)
    }

    func presentNotice(title: String) {
        let contextNoticePresenter: NoticePresenter = {
            let noticePresenter = DefaultNoticePresenter()
            noticePresenter.presentingViewController = tabBarController
            return noticePresenter
        }()
        contextNoticePresenter.enqueue(notice: .init(title: title))
    }

    func presentNotice(notice: Notice) {
        let contextNoticePresenter: NoticePresenter = {
            let noticePresenter = DefaultNoticePresenter()
            noticePresenter.presentingViewController = tabBarController
            return noticePresenter
        }()
        contextNoticePresenter.enqueue(notice: notice)
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

        configureNavigationBarLeftButtonItems()
        configureNavigationBarRightButtonItems()
    }

    func configureNavigationBarLeftButtonItems() {
        configureLeftBarBarButtomItemAsScanningButtonIfApplicable()
    }

    func configureNavigationBarRightButtonItems() {
        var rightBarButtonItems = [UIBarButtonItem]()
        rightBarButtonItems.append(addProductButton)

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

        let bulkEditItem: UIBarButtonItem = {
            let button = UIBarButtonItem(image: .multiSelectIcon,
                                         style: .plain,
                                         target: self,
                                         action: #selector(startBulkEditing))
            button.accessibilityTraits = .button
            button.accessibilityLabel = Localization.bulkEditingNavBarButtonTitle
            button.accessibilityHint = Localization.bulkEditingNavBarButtonHint

            return button
        }()
        rightBarButtonItems.append(bulkEditItem)


        navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    func configureNavigationBarForEditing() {
        updateNavigationBarTitleForEditing()
        configureNavigationBarItemsForEditing()
    }

    func updateNavigationBarTitleForEditing() {
        let selectedProducts = viewModel.selectedProductsCount
        if selectedProducts == 0 {
            navigationItem.title = Localization.bulkEditingTitle
        } else {
            navigationItem.title = String.localizedStringWithFormat(Localization.bulkEditingItemsTitle, String(selectedProducts))
        }
    }

    func configureNavigationBarItemsForEditing() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(finishBulkEditing))
        navigationItem.rightBarButtonItems = [bulkEditButton]
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
        tableView.dataSource = self
        tableView.delegate = self

        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension

        tableView.backgroundColor = .listBackground
        tableView.tableFooterView = footerSpinnerView
        tableView.separatorStyle = .none

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.accessibilityIdentifier = "products-table-view"

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

    private func configureHiddenScrollView() {
        // Configure large title using the `hiddenScrollView` trick.
        hiddenScrollView.configureForLargeTitleWorkaround()
        // Adds the "hidden" scroll view to the root of the UIViewController for large title workaround.
        view.addSubview(hiddenScrollView)
        view.sendSubviewToBack(hiddenScrollView)
        hiddenScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(hiddenScrollView, insets: .zero)
    }

    /// Configure toolbar view by number of products
    ///
    private func configureToolbar() {
        setupToolbar()
        showOrHideToolbar()
    }

    private func setupToolbar() {
        let sortTitle = NSLocalizedString("Sort by", comment: "Title of the toolbar button to sort products in different ways.")
        let sortButton = UIButton(frame: .zero)
        sortButton.setTitle(sortTitle, for: .normal)
        sortButton.addTarget(self, action: #selector(sortButtonTapped(sender:)), for: .touchUpInside)

        let filterTitle = NSLocalizedString("Filter", comment: "Title of the toolbar button to filter products by different attributes.")
        filterButton.setTitle(filterTitle, for: .normal)
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        filterButton.accessibilityIdentifier = "product-filter-button"

        [sortButton, filterButton].forEach {
            $0.applyLinkButtonStyle()
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = Constants.toolbarButtonInsets
            $0.configuration = configuration
        }

        toolbar.backgroundColor = .systemColor(.secondarySystemGroupedBackground)
        toolbar.setSubviews(leftViews: [sortButton], rightViews: [filterButton])

        toolbarBottomSeparator.backgroundColor = .systemColor(.separator)
        toolbarBottomSeparatorHeightConstraint.constant = 1.0 / UIScreen.main.scale
    }

    func configureScrollWatcher() {
        scrollWatcher.startObservingScrollPosition(tableView: tableView)
    }

    func configurePaginationTracker() {
        paginationTracker.delegate = self
        scrollWatcherSubscription = scrollWatcher.trigger.sink { [weak self] _ in
            self?.paginationTracker.ensureNextPageIsSynced()
        }
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
    func showOrHideToolbar() {
        guard !tableView.isEditing else {
            toolbar.isHidden = true
            return
        }

        toolbar.isHidden = filters.numberOfActiveFilters == 0 ? isEmpty : false
    }

    func configureStorePlanBannerPresenter() {
        self.storePlanBannerPresenter =  StorePlanBannerPresenter(viewController: self,
                                                                  containerView: view,
                                                                  siteID: siteID) { [weak self] bannerHeight in
            self?.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bannerHeight, right: 0)
        }
    }
}

// MARK: - Updates
//
private extension ProductsViewController {

    /// Slightly reveal swipe actions of the first visible cell that contains at least one swipe action.
    /// This action is performed only once, using `swipeActionsGlanced` as a control variable.
    ///
    func glanceTrailingActionsIfNeeded() {
        if !swipeActionsGlanced {
            swipeActionsGlanced = true
            tableView.glanceTrailingSwipeActions()
        }
    }

    /// Displays an error banner if there is an error loading products data.
    ///
    func showTopBannerViewIfNeeded() {
        if let error = dataLoadingError {
            requestAndShowErrorTopBannerView(for: error)
        }
    }

    /// Request a new product banner from `ProductsTopBannerFactory` and wire actionButtons actions
    /// To show a top banner, we can dispatch a loadFeedbackVisibility action from AppSettingsStore and update the top banner accordingly
    /// Ref: https://github.com/woocommerce/woocommerce-ios/issues/6682
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
            self?.hideTopBannerView()
        }, onCompletion: { [weak self] topBannerView in
            self?.topBannerContainerView.updateSubview(topBannerView)
            self?.topBannerView = topBannerView
            self?.updateTableHeaderViewHeight()
        })
    }

    /// Request a new error loading data banner from `ErrorTopBannerFactory` and display it in the table header
    ///
    func requestAndShowErrorTopBannerView(for error: Error) {
        let errorBanner = ErrorTopBannerFactory.createTopBanner(for: error,
            expandedStateChangeHandler: { [weak self] in
                self?.tableView.updateHeaderHeight()
            },
            onTroubleshootButtonPressed: { [weak self] in
                guard let self else { return }

                WebviewHelper.launch(ErrorTopBannerFactory.troubleshootUrl(for: error), with: self)
            },
            onContactSupportButtonPressed: { [weak self] in
                guard let self = self else { return }
                let supportForm = SupportFormHostingController(viewModel: .init())
                supportForm.show(from: self)
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
                                                           productType: filters.promotableProductType?.productType)

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
        showOrHideToolbar()
        addOrRemoveOverlay()
        tableView.reloadData()
        onDataReloaded.send(())
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

    /// We sync the local product settings for configuring local sorting and filtering.
    /// If there are some info stored when this screen is loaded, the data will be updated using the stored sort/filters.
    /// If any of the filters has to be synchronize remotely, it is done so after the filters are loaded, and the data updated if necessary.
    /// If no info are stored (so there is a failure), we resynchronize the syncingCoordinator for updating the screen using the default sort/filters.
    ///
    func syncProductsSettings() {
        syncLocalProductsSettings { [weak self] (result) in
            guard let self else { return }

            if result.isFailure {
                paginationTracker.resync()
            } else {
                // Emits `onDataReloaded` when local product settings (filters & sort order) are loaded and synced, so that
                // the first product selected in `selectFirstProductIfAvailable` is only triggered when the results match
                // the product settings.
                onDataReloaded.send(())
            }
        }
    }

    func observeSelectedProductAndDataLoadedStateToUpdateSelectedRow() {
        Publishers.CombineLatest3(selectedProduct,
                                  // Giving it an initial value to enable the combined publisher from the beginning.
                                  onDataReloaded.merge(with: Just<Void>(())),
                                  // Giving it an initial value to enable the combined publisher from the beginning.
                                  onTableViewEditingEnd.merge(with: Just<Void>(())))
            .map { $0.0 }
            .withPrevious()
            .sink { [weak self] previousSelectedProduct, selectedProduct in
                guard let self else { return }

                let currentSelectedIndexPath = tableView.indexPathForSelectedRow
                let selectedIndexPath = selectedProduct != nil ? resultsController.indexPath(forObjectMatching: {
                    $0.productID == selectedProduct?.productID
                }): nil
                if let selectedIndexPath {
                    guard currentSelectedIndexPath != selectedIndexPath else {
                        return
                    }
                    if let currentSelectedIndexPath {
                        tableView.deselectRow(at: currentSelectedIndexPath, animated: false)
                    }

                    let scrollPosition: UITableView.ScrollPosition = {
                        let hasSelectedProductChanged = (selectedProduct != previousSelectedProduct)
                        guard hasSelectedProductChanged else { return .none }
                        let isSelectedIndexPathVisible = self.isIndexPathVisible(selectedIndexPath)
                        return isSelectedIndexPathVisible ? .none : .middle
                    }()

                    tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: scrollPosition)
                } else if let currentSelectedIndexPath {
                    tableView.deselectRow(at: currentSelectedIndexPath, animated: false)
                }
            }
            .store(in: &subscriptions)
    }

    func observeSelectedProductToAutoScrollWhenProductChanges() {
        selectedProduct.compactMap { $0 }
            .sink { [weak self] selectedProduct in
                self?.listenToSelectedProductToAutoScrollWhenProductChanges(product: selectedProduct)
            }
            .store(in: &subscriptions)
    }

    func listenToSelectedProductToAutoScrollWhenProductChanges(product: Product) {
        selectedProductListener = .init(storageManager: ServiceLocator.storageManager, readOnlyEntity: product)
        selectedProductListener?.onUpsert = { [weak self] product in
            guard let self,
                  let selectedIndexPath = tableView.indexPathForSelectedRow,
                  !isIndexPathVisible(selectedIndexPath) else {
                return
            }
            tableView.scrollToRow(at: selectedIndexPath, at: .middle, animated: false)
        }
    }

    func isIndexPathVisible(_ indexPath: IndexPath) -> Bool {
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else {
            return false
        }
        return indexPathsForVisibleRows.contains(indexPath)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        resultsController.sections[section].numberOfObjects
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
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (splitViewController?.isCollapsed == true || !isSplitViewEnabled) &&
            !tableView.isEditing {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let product = resultsController.object(at: indexPath)

        if tableView.isEditing {
            viewModel.selectProduct(product)
            updatedSelectedItems()
        } else {
            ServiceLocator.analytics.track(event:
                    .Products.productListProductTapped(horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))

            didSelectProduct(product: product)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard tableView.isEditing else {
            return
        }

        let product = resultsController.object(at: indexPath)
        viewModel.deselectProduct(product)
        updatedSelectedItems()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let productIndex = resultsController.objectIndex(from: indexPath)

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid yout yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height

        // Restore cell selection state
        if tableView.isEditing {
            let product = resultsController.object(at: indexPath)
            if self.viewModel.productIsSelected(product) {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        onTableViewEditingEnd.send(())
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        hiddenScrollView.updateFromScrollViewDidScrollEventForLargeTitleWorkaround(scrollView)
    }

    /// Provide an implementation to show cell swipe actions. Return `nil` to provide no action.
    ///
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let product = resultsController.object(at: indexPath)
        guard ServiceLocator.stores.sessionManager.defaultSite?.visibility == .publicSite,
              product.productStatus == .published,
              let url = URL(string: product.permalink),
            let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        let shareAction = UIContextualAction(style: .normal, title: nil, handler: { [weak self] _, _, completionHandler in
            guard let self,
                  let navigationController = self.navigationController else {
                return
            }
            let shareProductCoordinator = ShareProductCoordinator(siteID: self.siteID,
                                                                  productURL: url,
                                                                  productName: product.name,
                                                                  productDescription: product.fullDescription ?? product.shortDescription ?? "",
                                                                  shareSheetAnchorView: cell,
                                                                  navigationController: navigationController)
            shareProductCoordinator.start()
            self.shareProductCoordinator = shareProductCoordinator
            ServiceLocator.analytics.track(.productListShareButtonTapped)
            completionHandler(true) // Tells the table that the action was performed and forces it to go back to its original state (un-swiped)
        })
        shareAction.backgroundColor = .brand
        shareAction.image = .init(systemName: "square.and.arrow.up")

        return UISwipeActionsConfiguration(actions: [shareAction])
    }
}

private extension ProductsViewController {
    func didSelectProduct(product: Product) {
        guard isSplitViewEnabled else {
            ProductDetailsFactory.productDetails(product: product,
                                                 presentationStyle: .navigationStack,
                                                 forceReadOnly: false) { [weak self] viewController in
                self?.navigationController?.pushViewController(viewController, animated: true)
            }
            return
        }
        navigateToContent(.productForm(product: product))
    }
}

// MARK: - Actions
//
private extension ProductsViewController {
    @objc private func pullToRefresh(sender: UIRefreshControl) {
        ServiceLocator.analytics.track(.productListPulledToRefresh)

        paginationTracker.resync {
            sender.endRefreshing()
        }
    }

    @objc func sortButtonTapped(sender: UIButton) {
        ServiceLocator.analytics.track(.productListViewSortingOptionsTapped)
        let title = NSLocalizedString("Sort by",
                                      comment: "Message title for sort products action bottom sheet")
        let viewProperties = BottomSheetListSelectorViewProperties(subtitle: title)
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
        ServiceLocator.analytics.track(event: .ProductListFilter.productListViewFilterOptionsTapped(source: .productsTab))
        let viewModel = FilterProductListViewModel(filters: filters, siteID: siteID)
        let filterProductListViewController = FilterListViewController(viewModel: viewModel, onFilterAction: { [weak self] filters in
            ServiceLocator.analytics.track(event: .ProductListFilter.productFilterListShowProductsButtonTapped(source: .productsTab, filters: filters))
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
        filters = FilterProductListViewModel.Filters()
    }

    /// Presents productsFeedback survey.
    ///
    func presentProductsFeedback() {
        let navigationController = SurveyCoordinatingController(survey: .productsFeedback)
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - Placeholders
//
private extension ProductsViewController {

    /// Displays the overlay when there are no results.
    ///
    func displayNoResultsOverlay() {
        // Abort if we are already displaying this childController
        guard emptyStateViewController?.parent == nil else {
            return
        }
        let emptyStateViewController = EmptyStateViewController(style: .list)
        let config = createFilterConfig()
        displayEmptyStateViewController(emptyStateViewController)
        emptyStateViewController.configure(config)

        // Make sure the banner is on top of the empty state view
        storePlanBannerPresenter?.bringBannerToFront()
    }

    func createFilterConfig() ->  EmptyStateViewController.Config {
        if filters.numberOfActiveFilters == 0 {
            return createNoProductsConfig()
        } else {
            return createNoProductsMatchFilterConfig()
        }
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
            buttonTitle: buttonTitle,
            onTap: { [weak self] button in
                self?.addProduct(sourceView: button, isFirstProduct: true)
            },
            onPullToRefresh: { [weak self] refreshControl in
                self?.pullToRefresh(sender: refreshControl)
            })
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
            buttonTitle: buttonTitle,
            onTap: { [weak self] button in
                self?.clearFilter(sourceView: button)
            },
            onPullToRefresh: { [weak self] refreshControl in
                self?.pullToRefresh(sender: refreshControl)
            })
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

    func configureLeftBarBarButtomItemAsScanningButtonIfApplicable() {
        viewModel.scanToUpdateInventoryButtonShouldBeVisible(completion: { shouldBeVisible in
            switch shouldBeVisible {
            case true:
                self.navigationItem.leftBarButtonItem = self.createAddOrderByProductScanningButtonItem()
            case false:
                self.navigationItem.leftBarButtonItem = nil
            }
        })
    }

    func createAddOrderByProductScanningButtonItem() -> UIBarButtonItem {
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
        button.accessibilityIdentifier = "product-scan-button"

        return button
    }
}

// MARK: - Sync'ing Helpers
//
extension ProductsViewController: PaginationTrackerDelegate {

    /// Synchronizes the Products for the Default Store (if any).
    ///
    func sync(pageNumber: Int, pageSize: Int, reason: String?, onCompletion: SyncCompletion?) {
        transitionToSyncingState(pageNumber: pageNumber)
        dataLoadingError = nil

        let action = ProductAction
            .synchronizeProducts(siteID: siteID,
                                 pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 stockStatus: filters.stockStatus,
                                 productStatus: filters.productStatus,
                                 productType: filters.promotableProductType?.productType,
                                 productCategory: filters.productCategory,
                                 sortOrder: sortOrder) { [weak self] result in
                                    guard let self = self else {
                                        return
                                    }

                                    switch result {
                                    case .failure(let error):
                                        ServiceLocator.analytics.track(.productListLoadError, withError: error)
                                        DDLogError("⛔️ Error synchronizing products: \(error)")
                                        self.dataLoadingError = error
                                    case .success:
                                        ServiceLocator.analytics.track(
                                            event: .ProductsList.productListLoaded(
                                                isEligibleForSubscriptions:
                                                    viewModel.isEligibleForSubscriptions
                                            )
                                        )
                                    }

                                    self.transitionToResultsUpdatedState()
                                    onCompletion?(result)
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
                                                              productTypeFilter: filters.promotableProductType?.productType,
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
                self?.syncProductCategoryFilterRemotely(from: settings) { [weak self] settings in
                    guard let self else { return }
                    if let sort = settings.sort {
                        sortOrder = ProductsSortOrder(rawValue: sort) ?? .default
                    }

                    let promotableProductType = settings.productTypeFilter.map { PromotableProductType(productType: $0, isAvailable: true, promoteUrl: nil) }
                    filters = FilterProductListViewModel.Filters(stockStatus: settings.stockStatusFilter,
                                                                 productStatus: settings.productStatusFilter,
                                                                 promotableProductType: promotableProductType,
                                                                 productCategory: settings.productCategoryFilter,
                                                                 numberOfActiveFilters: settings.numberOfActiveFilters())
                    onCompletion(result)
                }
            case let .failure(error):
                DDLogError("⛔️ Error loading product settings: \(error)")
                onCompletion(result)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Syncs the Product Category filter of settings remotely. This is necessary in case the category information was updated
    /// or the category itself removed.
    ///
    private func syncProductCategoryFilterRemotely(from settings: StoredProductSettings.Setting,
                                                   onCompletion: @escaping (StoredProductSettings.Setting) -> Void) {
        categoryHasChangedRemotely = false
        guard let productCategory = settings.productCategoryFilter else {
            onCompletion(settings)
            return
        }

        let action = ProductCategoryAction.synchronizeProductCategory(siteID: siteID, categoryID: productCategory.categoryID) { [weak self] result in
            guard let self else { return }
            var updatingProductCategory: ProductCategory? = productCategory

            switch result {
            case .success(let productCategory):
                updatingProductCategory = productCategory
            case .failure(let error):
                if let error = error as? ProductCategoryActionError,
                   case .categoryDoesNotExistRemotely = error {
                    // The product category was removed
                    updatingProductCategory = nil
                }
            }

            var completionSettings = settings
            if updatingProductCategory != productCategory {
                categoryHasChangedRemotely = true
                completionSettings = StoredProductSettings.Setting(siteID: settings.siteID,
                                                                sort: settings.sort,
                                                                stockStatusFilter: settings.stockStatusFilter,
                                                                productStatusFilter: settings.productStatusFilter,
                                                                productTypeFilter: settings.productTypeFilter,
                                                                productCategoryFilter: updatingProductCategory)
            }

            onCompletion(completionSettings)
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
            let isFirstPage = pageNumber == SyncingCoordinator.Defaults.pageFirstIndex
            if isFirstPage && resultsController.isEmpty {
                displayGhostContent(over: tableView)
            } else if !isFirstPage {
                ensureFooterSpinnerIsStarted()
            }
            // Remove error banner when sync starts
            if dataLoadingError != nil {
                hideTopBannerView()
            }
        case .results:
            glanceTrailingActionsIfNeeded()
        }
    }

    func didLeave(state: PaginatedListViewControllerState) {
        switch state {
        case .noResultsPlaceholder:
            removeAllOverlays()
        case .syncing:
            ensureFooterSpinnerIsStopped()
            removeGhostContent()
            showTopBannerViewIfNeeded()
            showOrHideToolbar()
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
private extension ProductsViewController {

    /// Starts the Footer Spinner animation, whenever `mustStartFooterSpinner` returns *true*.
    ///
    func ensureFooterSpinnerIsStarted() {
        tableView.tableFooterView = footerSpinnerView
        footerSpinnerView.startAnimating()
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
        static let toolbarButtonInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }

    enum Localization {
        static let bulkEditingNavBarButtonTitle = NSLocalizedString("Edit products", comment: "Action to start bulk editing of products")
        static let bulkEditingNavBarButtonHint = NSLocalizedString(
            "Edit status or price for multiple products at once",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to bulk edit products"
        )

        static let selectAllToolbarButtonTitle = NSLocalizedString(
            "Select all",
            comment: "Title of a button that selects all products for bulk update"
        )
        static let bulkEditingToolbarButtonTitle = NSLocalizedString(
            "Bulk update",
            comment: "Title of a button that presents a menu with possible products bulk update options"
        )
        static let bulkEditingStatusOption = NSLocalizedString("Update status", comment: "Title of an option that opens bulk products status update flow")
        static let bulkEditingPriceOption = NSLocalizedString("Update price", comment: "Title of an option that opens bulk products price update flow")
        static let cancel = NSLocalizedString("Cancel", comment: "Title of an option to dismiss the bulk edit action sheet")

        static let bulkEditingTitle = NSLocalizedString(
            "Select items",
            comment: "Title that appears on top of the Product List screen when bulk editing starts."
        )
        static let bulkEditingItemsTitle = NSLocalizedString(
            "%1$@ selected",
            comment: "Title that appears on top of the Product List screen during bulk editing. Reads like: 2 selected"
        )

        static let bulkEditingApply = NSLocalizedString("Apply", comment: "Title for the button to apply bulk editing changes to selected products.")

        static let productsSavingTitle = NSLocalizedString("Updating your products...",
                                                          comment: "Title of the in-progress UI while bulk updating selected products remotely")
        static let productsSavingMessage = NSLocalizedString("Please wait while we update these products on your store",
                                                            comment: "Message of the in-progress UI while bulk updating selected products remotely")

        static let statusUpdatedNotice = NSLocalizedString("Status updated",
                                                           comment: "Title of the notice when a user updated status for selected products")
        static let priceUpdatedNotice = NSLocalizedString("Price updated",
                                                           comment: "Title of the notice when a user updated price for selected products")
        static let updateErrorNotice = NSLocalizedString("Cannot update products",
                                                         comment: "Title of the notice when there is an error updating selected products")
        static let updateInventoryNotice = NSLocalizedString(
            "updateInventoryNotice.scanProducts.createAddOrderByProductScanningButtonItem",
            value: "Quantity updated: %@",
            comment: "Message of the notice when inventory is updated successfully. Style may vary based on store settings." +
            "Reads like: 'Quantity updated: 2,345'"
        )
    }
}
