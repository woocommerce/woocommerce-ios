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
        switchDetailsHandler: switchDetailsHandler
    )

    // Used to trick the navigation bar for large title (ref: issue 3 in p91TBi-45c-p2).
    private let hiddenScrollView = UIScrollView()

    private let siteID: Int64

    private let analytics = ServiceLocator.analytics

    /// Stores any active observation.
    ///
    private var subscriptions = Set<AnyCancellable>()

    private let barcodeSKUScannerItemFinder: BarcodeSKUScannerItemFinder

    /// The top bar for apply filters, that will be embedded inside the stackview, on top of everything.
    ///
    private var filtersBar: FilteredOrdersHeaderBar = {
        let filteredOrdersBar: FilteredOrdersHeaderBar = FilteredOrdersHeaderBar.instantiateFromNib()
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

    private var barcodeScannerCoordinator: ProductSKUBarcodeScannerCoordinator?

    private let switchDetailsHandler: OrderListViewController.SelectOrderDetails


    // MARK: View Lifecycle

    init(siteID: Int64,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         orderDurationRecorder: OrderDurationRecorderProtocol = OrderDurationRecorder.shared,
         barcodeSKUScannerItemFinder: BarcodeSKUScannerItemFinder = BarcodeSKUScannerItemFinder(),
         switchDetailsHandler: @escaping OrderListViewController.SelectOrderDetails) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.featureFlagService = ServiceLocator.featureFlagService
        self.orderDurationRecorder = orderDurationRecorder
        self.barcodeSKUScannerItemFinder = barcodeSKUScannerItemFinder
        self.switchDetailsHandler = switchDetailsHandler
        super.init(nibName: Self.nibName, bundle: nil)

        configureTitle()
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

    override var shouldShowOfflineBanner: Bool {
        // Should show the offline banner only when there's no orderDetailsViewController in memory
        // otherwise, it will be shown within the order details view, so there's no need to duplicate it
        if orderDetailsViewController != nil {
            return false
        } else {
            return true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Clears application icon badge
        ServiceLocator.pushNotesManager.resetBadgeCount(type: .storeOrder)
        updateTimeoutText()
    }

    /// Shows `SearchViewController`.
    ///
    @objc private func displaySearchOrders() {
        analytics.track(.ordersListSearchTapped)

        let searchViewController = SearchViewController<OrderTableViewCell, OrderSearchUICommand>(
            storeID: siteID,
            command: OrderSearchUICommand(siteID: siteID,
                                          onSelectSearchResult: { [weak self] order, viewController in
                                              guard let self else { return }
                                              guard featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) else {
                                                  return presentOrder(order, from: viewController)
                                              }
                                              navigateToOrderDetail(order)
                                              viewController.dismiss(animated: true)
                                          }),
            cellType: OrderTableViewCell.self,
            cellSeparator: .singleLine)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }

    private func presentOrder(_ order: Order, from viewController: UIViewController) {
        let viewModel = OrderDetailsViewModel(order: order)
        let detailsViewController = OrderDetailsViewController(viewModel: viewModel)

        viewController.navigationController?.pushViewController(detailsViewController, animated: true)
        analytics.track(event: .Orders.orderOpen(
            order: order,
            horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
    }

    /// Selects the order given the ID from the order list view if the order exists locally.
    /// - Parameter orderID: ID of the order to select in the list.
    /// - Returns: Whether the order to select is in the list already (i.e. the order has been fetched and exists locally).
    @discardableResult
    func selectOrderFromListIfPossible(for orderID: Int64) -> Bool {
        ordersViewController.selectOrderFromListIfPossible(for: orderID)
    }

    /// Called when an order is shown externally (outside of `OrderListViewController`) and the order should be
    /// selected in the order list.
    /// - Parameter orderID: ID of the order to be selected in the order list.
    func onOrderSelected(id orderID: Int64) {
        ordersViewController.onOrderSelected(id: orderID)
    }

    /// Presents the Order Creation flow.
    ///
    @objc func presentOrderCreationFlow() {
        let viewModel = EditableOrderViewModel(siteID: siteID)
        setupNavigation(viewModel: viewModel)
    }

    /// Presents the Order Creation flow with a scanned Product
    ///
    private func presentOrderCreationFlowWithScannedProduct(_ result: SKUSearchResult) {
        let viewModel = EditableOrderViewModel(siteID: siteID, initialItem: result)
        setupNavigation(viewModel: viewModel)
    }

    /// Presents the Order Creation flow with the given customer pre-filled.
    ///
    func presentOrderCreationFlowWithCustomer(id customerID: Int64, billing: Address?, shipping: Address?) {
        let viewModel = EditableOrderViewModel(siteID: siteID, initialCustomer: (customerID, billing, shipping))
        setupNavigation(viewModel: viewModel)
    }

    /// Coordinates the navigation between the different views involved in Order Creation, Editing, and Details
    ///
    private func setupNavigation(viewModel: EditableOrderViewModel) {
        guard let navigationController = navigationController else {
            return
        }

        let viewController = OrderFormHostingController(viewModel: viewModel)

        viewModel.onFinished = { [weak self] order in
            guard let self = self else { return }

            self.dismiss(animated: true) {
                self.navigateToOrderDetail(order)
            }
        }

        viewModel.onFinishAndCollectPayment = { [weak self] order, paymentMethodsViewModel in
            self?.dismiss(animated: true) {
                self?.navigateToOrderDetail(order) { [weak self] _ in
                    guard let self,
                          let orderDetailsViewController = self.orderDetailsViewController else {
                        return
                    }
                    let paymentMethodsViewController = PaymentMethodsHostingController(viewModel: paymentMethodsViewModel)
                    paymentMethodsViewController.parentController = orderDetailsViewController
                    orderDetailsViewController.present(paymentMethodsViewController, animated: true)
                }
            }
        }

        if featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) {
            viewController.modalPresentationStyle = .overFullScreen
            navigationController.present(viewController, animated: true)
        } else {
            let newOrderNavigationController = WooNavigationController(rootViewController: viewController)
            navigationController.present(newOrderNavigationController, animated: true)
        }

        analytics.track(event: .Orders.orderAddNew())
        orderDurationRecorder.startRecording()
    }

    /// Presents the Order Creation flow when a product is scanned
    ///
    @objc func presentOrderCreationFlowByProductScanning() {
        analytics.track(event: .Orders.orderAddNewFromBarcodeScanningTapped())

        guard let navigationController = navigationController else {
            return
        }

        let productSKUBarcodeScannerCoordinator = ProductSKUBarcodeScannerCoordinator(sourceNavigationController: navigationController,
                                                                                      onSKUBarcodeScanned: { [weak self] scannedBarcode in
            self?.analytics.track(event: .BarcodeScanning.barcodeScanningSuccess(from: .orderList))

            self?.navigationItem.configureLeftBarButtonItemAsLoader()
            self?.handleScannedBarcode(scannedBarcode) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(product):
                    self.analytics.track(event: .Orders.orderProductAdd(flow: .creation,
                                                                                         source: .orderList,
                                                                                         addedVia: .scanning,
                                                                                         includesBundleProductConfiguration: false))
                    self.presentOrderCreationFlowWithScannedProduct(product)
                case let .failure(error):
                    self.displayScannedProductErrorNotice(error, code: scannedBarcode)
                }
                navigationItem.leftBarButtonItem = createAddOrderByProductScanningButtonItem()
            }
        }, onPermissionsDenied: { [weak self] in
            self?.analytics.track(event: .BarcodeScanning.barcodeScanningFailure(from: .orderList, reason: .cameraAccessNotPermitted))
        })
        barcodeScannerCoordinator = productSKUBarcodeScannerCoordinator
        productSKUBarcodeScannerCoordinator.start()
    }

    /// Handles the result of scanning a barcode
    ///
    /// - Parameters:
    ///   - scannedBarcode: The scanned barcode
    ///   - onCompletion: The closure to be trigged when the scanning completes. Succeeds with a Product, or fails with an Error.
    private func handleScannedBarcode(_ scannedBarcode: ScannedBarcode, onCompletion: @escaping ((Result<SKUSearchResult, Error>) -> Void)) {
        Task {
            do {
                let result = try await barcodeSKUScannerItemFinder.searchBySKU(from: scannedBarcode, siteID: siteID, source: .orderList)
                onCompletion(.success(result))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    /// Presents an Error notice
    ///
    private func displayScannedProductErrorNotice(_ error: Error, code: ScannedBarcode) {
        let notice = BarcodeSKUScannerErrorNoticeFactory.notice(for: error, code: code) { [weak self] in
            self?.presentOrderCreationFlowByProductScanning()
        }

        ordersViewController.showErrorNotice(notice, in: self)
    }

    /// Present `FilterListViewController`
    ///
    private func filterButtonTapped() {
        analytics.track(.orderListViewFilterOptionsTapped)

        // Fetch stored statuses
        do {
            try statusResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch stored statuses for Site \(siteID): \(error)")
        }

        let allowedStatuses = statusResultsController.fetchedObjects.map { $0 }

        let viewModel = FilterOrderListViewModel(filters: filters, allowedStatuses: allowedStatuses, siteID: siteID)
        let filterOrderListViewController = FilterListViewController(viewModel: viewModel, onFilterAction: { [weak self] filters in
            self?.filters = filters

            self?.analytics.track(event: .OrdersFilter.onFilterOrders(filters: filters))
        }, onClearAction: {
        }, onDismissAction: {
        })
        present(filterOrderListViewController, animated: true, completion: nil)
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
    ///
    func configureNavigationButtons() {
        navigationItem.leftBarButtonItem = createAddOrderByProductScanningButtonItem()
        navigationItem.rightBarButtonItems = [
            createAddOrderItem(),
            createSearchBarButtonItem()
        ]
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

    func orderListViewControllerSyncTimestampChanged(_ syncTimestamp: Date) {
        updateTimeoutText()
    }

    func orderListScrollViewDidScroll(_ scrollView: UIScrollView) {
        hiddenScrollView.updateFromScrollViewDidScrollEventForLargeTitleWorkaround(scrollView)
    }

    func clearFilters() {
        filters = FilterOrderListViewModel.Filters()
    }

    private func updateTimeoutText() {
        let syncTimestamp = OrderListSyncBackgroundTask.latestSyncDate

        // Prevents an old date to be displayed when there isn't a sync timestamp.
        guard syncTimestamp != .distantPast else {
            return
        }

        let dateFormatter = syncTimestamp.isSameDay(as: Date.now) ? DateFormatter.timeFormatter : DateFormatter.dateAndTimeFormatter
        filtersBar.setLastUpdatedTime(dateFormatter.string(from: syncTimestamp))
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
                                                                 product: settings.productFilter,
                                                                 customer: settings.customerFilter,
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
                                                            orderStatusesFilter: filters.orderStatus,
                                                            dateRangeFilter: filters.dateRange,
                                                            productFilter: filters.product,
                                                            customerFilter: filters.customer) { error in
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
        button.accessibilityLabel = NSLocalizedString(
            "orderForm.products.add.scan.button.accessibilityLabel",
            value: "Scan barcode",
            comment: "Accessibility label for the barcode scanning button to add product")
        button.accessibilityIdentifier = "create-new-order-by-product-scanning"
        return button
    }

    /// Pushes an `OrderDetailsViewController` onto the navigation stack.
    ///
    private func navigateToOrderDetail(_ order: Order, onCompletion: ((Bool) -> Void)? = nil) {
        analytics.track(event: .Orders.orderOpen(
            order: order,
            horizontalSizeClass: UITraitCollection.current.horizontalSizeClass
        ))

        ordersViewController.showOrderDetails(order, shouldScrollIfNeeded: true) { _ in
            onCompletion?(true)
        }
    }

    var orderDetailsViewController: OrderDetailsViewController? {
        guard let secondaryViewNavigationController = splitViewController?.viewController(for: .secondary) as? UINavigationController else {
            return nil
        }
        return secondaryViewNavigationController.topViewController as? OrderDetailsViewController
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
    }
}
