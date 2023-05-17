import UIKit
import Yosemite
import Combine
import protocol Storage.StorageManagerType
import Experiments

/// The root tab controller for Orders, which contains the `OrderListViewController` .
///
final class OrdersRootViewController: UIViewController {

    // The stack view which will contain the top bar filters and the order list.
    @IBOutlet private weak var stackView: UIStackView!

    // MARK: Child view controller
    private lazy var orderListViewModel = OrderListViewModel(siteID: siteID, filters: filters)

    private lazy var ordersViewController = OrderListViewController(
        siteID: siteID,
        title: Localization.defaultOrderListTitle,
        viewModel: orderListViewModel,
        switchDetailsHandler: handleSwitchingDetails(viewModel:)
    )

    // Used to trick the navigation bar for large title (ref: issue 3 in p91TBi-45c-p2).
    private let hiddenScrollView = UIScrollView()

    private let siteID: Int64

    private let analytics = ServiceLocator.analytics

    /// Stores any active observation.
    ///
    private var subscriptions = Set<AnyCancellable>()

    /// The top bar for apply filters, that will be embedded inside the stackview, on top of everything.
    ///
    private var filtersBar: FilteredOrdersHeaderBar = {
        let filteredOrdersBar: FilteredOrdersHeaderBar = FilteredOrdersHeaderBar.instantiateFromNib()
        filteredOrdersBar.backgroundColor = .listForeground(modal: false)
        return filteredOrdersBar
    }()

    private var filters: FilterOrderListViewModel.Filters = FilterOrderListViewModel.Filters() {
        didSet {
            if filters != oldValue {
                updateLocalOrdersSettings(filters: filters)
                filtersBar.setNumberOfFilters(filters.numberOfActiveFilters)
                orderListViewModel.updateFilters(filters: filters)
            }
        }
    }

    private let storageManager: StorageManagerType

    /// Used for looking up the `OrderStatus` to show in the `Order Filters`.
    ///
    /// The `OrderStatus` data is fetched from the API by `OrderListViewModel`.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)
        let predicate = NSPredicate(format: "siteID == %lld", siteID)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    private let featureFlagService: FeatureFlagService

    private let orderDurationRecorder: OrderDurationRecorderProtocol

    // MARK: View Lifecycle

    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         orderDurationRecorder: OrderDurationRecorderProtocol = OrderDurationRecorder.shared) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.featureFlagService = ServiceLocator.featureFlagService
        self.orderDurationRecorder = orderDurationRecorder
        super.init(nibName: Self.nibName, bundle: nil)

        configureTitle()

        if !featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
            configureTabBarItem()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
        configureView()
        configureNavigationButtons()
        configureFiltersBar()
        configureChildViewController()

        /// We sync the local order settings for configuring local statuses and date range filters.
        /// If there are some info stored when this screen is loaded, the data will be updated using the stored filters.
        ///
        syncLocalOrdersSettings { [weak self] _ in
            guard let self = self else { return }
            self.configureStatusResultsController()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Clears application icon badge
        ServiceLocator.pushNotesManager.resetBadgeCount(type: .storeOrder)
    }

    override var shouldShowOfflineBanner: Bool {
        if featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
            return false
        }
        return true
    }

    /// Shows `SearchViewController`.
    ///
    @objc private func displaySearchOrders() {
        analytics.track(.ordersListSearchTapped)

        let searchViewController = SearchViewController<OrderTableViewCell, OrderSearchUICommand>(storeID: siteID,
                                                                                                  command: OrderSearchUICommand(siteID: siteID),
                                                                                                  cellType: OrderTableViewCell.self,
                                                                                                  cellSeparator: .singleLine)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }

    /// Presents the Details for the Notification with the specified Identifier.
    ///
    func presentDetails(for note: Note) {
        guard let orderID = note.meta.identifier(forKey: .order),
              let siteID = note.meta.identifier(forKey: .site) else {
            DDLogError("## Notification with [\(note.noteID)] lacks its OrderID!")
            return
        }

        presentDetails(for: Int64(orderID), siteID: Int64(siteID), note: note)
    }

    func presentDetails(for orderID: Int64, siteID: Int64, note: Note? = nil) {
        let loaderViewController = OrderLoaderViewController(orderID: Int64(orderID), siteID: Int64(siteID), note: note)
        navigationController?.pushViewController(loaderViewController, animated: true)
    }

    /// Presents the Order Creation flow.
    ///
    /// - parameter initialItem: Represents the product ID of an initial item to create the Order with, if given
    /// We default to use -1 as sentinel value, due not having a Swift's Int64 optional primitive equivalent in Obj-C,
    /// and validate it when needed.
    ///
    @objc func presentOrderCreationFlow(with initialItem: Int64 = -1) {
        guard let navigationController = navigationController else {
            return
        }

        let item: Int64? = validateSentinelValue(value: initialItem)

        let viewModel = EditableOrderViewModel(siteID: siteID, isCreatedFromScannedItem: item)
        viewModel.onFinished = { [weak self] order in
            guard let self = self else { return }

            self.dismiss(animated: true) {
                self.navigateToOrderDetail(order)
            }
        }

        let viewController = OrderFormHostingController(viewModel: viewModel)
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
            let newOrderNavigationController = WooNavigationController(rootViewController: viewController)
            navigationController.present(newOrderNavigationController, animated: true)
        } else {
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
        }

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.orderAddNew())
        orderDurationRecorder.startRecording()
    }

    /// Presents the Order Creation flow when a product is scanned
    ///
    @objc func presentOrderCreationFlowByProductScanning() {
        guard let navigationController = navigationController else {
            return
        }

        let productScannerViewController = ProductSKUInputScannerViewController(onBarcodeScanned: { [weak self] scannedBarcode in
            self?.handleScannedBarcode(scannedBarcode) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(product):
                    print("🍉 start order creation flow with Product \(product.productID)")
                    navigationController.popViewController(animated: true)
                    self.presentOrderCreationFlow(with: product.productID)
                case .failure:
                    print("🍉 something went wrong")
                    navigationController.popViewController(animated: true)
                    self.handleError()
                }
            }
        })
        navigationController.pushViewController(productScannerViewController, animated: true)
    }

    ///
    ///
    func handleScannedBarcode(_ scannedBarcode: String, onCompletion: @escaping ((Result<Product, Error>) -> Void)) {
        print("🍉 barcode detected: \(scannedBarcode)")
        let action = ProductAction.retrieveFirstProductMatchFromSKU(siteID: siteID, sku: scannedBarcode) { result in
            switch result {
            case let .success(matchedProduct):
                print("🍉 retrieval success: Product \(matchedProduct.productID)")
                onCompletion(.success(matchedProduct))
            case let .failure(error):
                print("🍉 retrieval error: \(error)")
                onCompletion(.failure(error))
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    ///
    ///
    func handleError() {
        let message = Localization.errorNoticeMessage
        ordersViewController.showErrorNotice(with: message, in: self)
    }

    /// Present `FilterListViewController`
    ///
    private func filterButtonTapped() {
        ServiceLocator.analytics.track(.orderListViewFilterOptionsTapped)

        // Fetch stored statuses
        do {
            try statusResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch stored statuses for Site \(siteID): \(error)")
        }

        let allowedStatuses = statusResultsController.fetchedObjects.map { $0 }

        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: allowedStatuses)
        let filterOrderListViewController = FilterListViewController(viewModel: viewModel, onFilterAction: { [weak self] filters in
            self?.filters = filters
            let statuses = (filters.orderStatus ?? []).map { $0.rawValue }.joined(separator: ",")
            let dateRange = filters.dateRange?.analyticsDescription ?? ""
            ServiceLocator.analytics.track(.ordersListFilter,
                                           withProperties: ["status": statuses,
                                                            "date_range": dateRange])
        }, onClearAction: {
        }, onDismissAction: {
        })
        present(filterOrderListViewController, animated: true, completion: nil)
    }

    /// This is to update the order detail in split view
    ///
    private func handleSwitchingDetails(viewModel: OrderDetailsViewModel?) {
        guard let viewModel = viewModel else {
            let emptyStateViewController = EmptyStateViewController(style: .basic)
            let config = EmptyStateViewController.Config.simple(
                message: .init(string: Localization.emptyOrderDetails),
                image: .emptySearchResultsImage
            )
            emptyStateViewController.configure(config)
            splitViewController?.showDetailViewController(UINavigationController(rootViewController: emptyStateViewController), sender: nil)
            return
        }

        let orderDetailsViewController = OrderDetailsViewController(viewModel: viewModel)
        let orderDetailsNavigationController = WooNavigationController(rootViewController: orderDetailsViewController)

        splitViewController?.showDetailViewController(orderDetailsNavigationController, sender: nil)
    }
}

// MARK: - Configuration
//
private extension OrdersRootViewController {

    func configureView() {
        view.backgroundColor = .listBackground
    }

    func configureTitle() {
        title = Localization.defaultOrderListTitle
    }

    /// Set up properties for `self` as a root tab bar controller.
    ///
    func configureTabBarItem() {
        tabBarItem.title = title
        tabBarItem.image = .pagesImage
        tabBarItem.accessibilityIdentifier = "tab-bar-orders-item"
    }

    /// Sets navigation buttons.
    /// Search: Is always present.
    /// Scan: Present when `.addProductToOrderViaSKUScanner` flag is enabled
    /// Add: Always present.
    ///
    func configureNavigationButtons() {
        var buttons: [UIBarButtonItem] = [
            createAddOrderItem(),
            createSearchBarButtonItem()
        ]
        if featureFlagService.isFeatureFlagEnabled(.addProductToOrderViaSKUScanner) {
            buttons.insert(createAddOrderByProductScanningButtonItem(), at: 1)
        }
        navigationItem.rightBarButtonItems = buttons
    }

    func configureFiltersBar() {
        // Display the filtered orders bar
        stackView.addArrangedSubview(filtersBar)
        filtersBar.onAction = { [weak self] in
            self?.filterButtonTapped()
        }
    }

    func configureChildViewController() {
        // Configure large title using the `hiddenScrollView` trick.
        hiddenScrollView.configureForLargeTitleWorkaround()
        // Adds the "hidden" scroll view to the root of the UIViewController for large title workaround.
        view.addSubview(hiddenScrollView)
        view.sendSubviewToBack(hiddenScrollView)
        hiddenScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(hiddenScrollView, insets: .zero)
        ordersViewController.delegate = self

        // Add contentView to stackview
        let contentView = ordersViewController.view!
        addChild(ordersViewController)
        stackView.addArrangedSubview(contentView)
        ordersViewController.didMove(toParent: self)
    }

    /// Connect hooks on `ResultsController` and query cached data.
    /// This is useful for stay up to date with the remote statuses, resetting the filters if one of the local status filters was deleted remotely.
    ///
    func configureStatusResultsController() {
        statusResultsController.onDidChangeObject = { [weak self] (updatedOrdersStatus, _, _, _) in
            guard let self = self else { return }
            self.resetFiltersIfAnyStatusFilterIsNoMoreExisting(orderStatuses: self.statusResultsController.fetchedObjects)
        }

        do {
            try statusResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch stored order statuses for Site \(siteID): \(error)")
        }
        resetFiltersIfAnyStatusFilterIsNoMoreExisting(orderStatuses: statusResultsController.fetchedObjects)
    }

    /// If the current applied status filters does not match the existing status filters fetched from API, we reset them.
    ///
    func resetFiltersIfAnyStatusFilterIsNoMoreExisting(orderStatuses: [OrderStatus]) {
        guard let storedOrderFilters = filters.orderStatus else { return }
        for storedOrderFilter in storedOrderFilters {
            if !orderStatuses.map({$0.status}).contains(storedOrderFilter) {
                clearFilters()
                break
            }
        }
    }
}

extension OrdersRootViewController: OrderListViewControllerDelegate {
    func orderListViewControllerWillSynchronizeOrders(_ viewController: UIViewController) {
        // Do nothing here
    }

    func orderListScrollViewDidScroll(_ scrollView: UIScrollView) {
        hiddenScrollView.updateFromScrollViewDidScrollEventForLargeTitleWorkaround(scrollView)
    }

    func clearFilters() {
        filters = FilterOrderListViewModel.Filters()
    }
}

// MARK: - Stored Order Settings (eg. filters)
private extension OrdersRootViewController {
    /// Fetch local Orders Settings (eg.  status or date range filters stored in Orders settings)
    ///
    func syncLocalOrdersSettings(onCompletion: @escaping (Result<StoredOrderSettings.Setting, Error>) -> Void) {
        let action = AppSettingsAction.loadOrdersSettings(siteID: siteID) { [weak self] (result) in
            switch result {
            case .success(let settings):
                self?.filters = FilterOrderListViewModel.Filters(orderStatus: settings.orderStatusesFilter,
                                                                 dateRange: settings.dateRangeFilter,
                                                                 numberOfActiveFilters: settings.numberOfActiveFilters())
            case .failure(let error):
                print("It was not possible to sync local orders settings: \(String(describing: error))")
            }
            onCompletion(result)
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Update local Orders Settings (eg. status or date range filters stored in Orders settings)
    ///
    func updateLocalOrdersSettings(filters: FilterOrderListViewModel.Filters) {
        let action = AppSettingsAction.upsertOrdersSettings(siteID: siteID,
                                                            orderStatusesFilter: filters.orderStatus, dateRangeFilter: filters.dateRange) { error in
            if error != nil {
                assertionFailure("It was not possible to store order settings due to an error: \(String(describing: error))")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - Creators

private extension OrdersRootViewController {
    /// Create a `UIBarButtonItem` to be used as the search button on the top-left.
    ///
    func createSearchBarButtonItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(image: .searchBarButtonItemImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(displaySearchOrders))
        button.accessibilityTraits = .button
        button.accessibilityLabel = Localization.accessibilityLabelSearchOrders
        button.accessibilityHint = Localization.accessibilityHintSearchOrders
        button.accessibilityIdentifier = "order-search-button"

        return button
    }

    /// Create a `UIBarButtonItem` to be used as a way to create a new order.
    ///
    func createAddOrderItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(image: .plusBarButtonItemImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(presentOrderCreationFlow))
        button.accessibilityTraits = .button
        button.accessibilityLabel = NSLocalizedString("Choose new order type", comment: "Opens action sheet to choose a type of a new order")
        button.accessibilityIdentifier = "new-order-type-sheet-button"
        return button
    }

    /// Creates a `UIBarButtonItem` to be used to create a new order by scanning a product
    ///
    func createAddOrderByProductScanningButtonItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(image: .scanImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(presentOrderCreationFlowByProductScanning))
        button.accessibilityTraits = .button
        button.accessibilityIdentifier = "create-new-order-by-product-scanning"
        return button
    }

    /// Pushes an `OrderDetailsViewController` onto the navigation stack.
    ///
    private func navigateToOrderDetail(_ order: Order) {
        let viewModel = OrderDetailsViewModel(order: order)
        guard !featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) else {
            return handleSwitchingDetails(viewModel: viewModel)
        }

        let orderViewController = OrderDetailsViewController(viewModel: viewModel)

        // Cleanup navigation (remove new order flow views) before navigating to order details
        if let navigationController = navigationController, let indexOfSelf = navigationController.viewControllers.firstIndex(of: self) {
            let viewControllersIncludingSelf = navigationController.viewControllers[0...indexOfSelf]
            navigationController.setViewControllers(viewControllersIncludingSelf + [orderViewController], animated: true)
        } else {
            show(orderViewController, sender: self)
        }

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.orderOpen(order: order))
    }
}

// MARK: - Helpers
private extension OrdersRootViewController {
    /// Validates the passed value by returning nil or a value
    ///
    func validateSentinelValue(value: Int64) -> Int64? {
        value == -1 ? nil : value
    }
}

// MARK: - Constants
private extension OrdersRootViewController {
    enum Localization {
        static let defaultOrderListTitle = NSLocalizedString("Orders", comment: "The title of the Orders tab.")
        static let accessibilityLabelSearchOrders = NSLocalizedString("Search orders", comment: "Search Orders")
        static let accessibilityHintSearchOrders = NSLocalizedString(
            "Retrieves a list of orders that contain a given keyword.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to search orders."
        )
        static let emptyOrderDetails = NSLocalizedString("No order selected",
                                                         comment: "Message on the detail view of the Orders tab before any order is selected")
        static let errorNoticeMessage = NSLocalizedString("Product not found. Failed to create a New Order",
                                                          comment: "Error message on the Order list view when the scanner cannot find a matching product " +
                                                          "and create a new order")
    }
}
