import UIKit
import Yosemite
import Combine

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
        emptyStateConfig: .simple(
            message: NSAttributedString(string: Localization.allOrdersEmptyStateMessage),
            image: .waitingForCustomersImage
        )
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
        filteredOrdersBar.backgroundColor = .listForeground
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

    /// Stores status for order creation availability.
    ///
    private var isOrderCreationEnabled: Bool = false

    // MARK: View Lifecycle

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: Self.nibName, bundle: nil)

        configureTitle()
        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
        configureView()
        configureFiltersBar()
        configureChildViewController()

        /// We sync the local order settings for configuring local statuses and date range filters.
        /// If there are some info stored when this screen is loaded, the data will be updated using the stored filters.
        ///
        syncLocalOrdersSettings { _ in }
    }

    override func viewWillAppear(_ animated: Bool) {
        // Needed in ViewWillAppear because this View Controller is never recreated.
        fetchExperimentalTogglesAndConfigureNavigationButtons()
    }

    override var shouldShowOfflineBanner: Bool {
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
        guard let orderID = note.meta.identifier(forKey: .order), let siteID = note.meta.identifier(forKey: .site) else {
            DDLogError("## Notification with [\(note.noteID)] lacks its OrderID!")
            return
        }

        let loaderViewController = OrderLoaderViewController(note: note, orderID: Int64(orderID), siteID: Int64(siteID))
        navigationController?.pushViewController(loaderViewController, animated: true)
    }

    /// Present `FilterListViewController`
    ///
    private func filterButtonTapped() {
        ServiceLocator.analytics.track(.orderListViewFilterOptionsTapped)
        let viewModel = FilterOrderListViewModel(filters: filters)
        let filterOrderListViewController = FilterListViewController(viewModel: viewModel, onFilterAction: { [weak self] filters in
            self?.filters = filters
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
    /// Search: Is always present.
    /// Add: Always present.
    ///
    func configureNavigationButtons(isOrderCreationExperimentalToggleEnabled: Bool) {
        let buttons: [UIBarButtonItem] = [
            createSearchBarButtonItem(),
            createAddOrderItem(isOrderCreationEnabled: isOrderCreationExperimentalToggleEnabled)
        ]
        navigationItem.rightBarButtonItems = buttons
    }

    func configureFiltersBar() {
        // Display the filtered orders bar
        // if the feature flag is enabled
        let isOrderListFiltersEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.orderListFilters)
        if isOrderListFiltersEnabled {
            stackView.addArrangedSubview(filtersBar)
        }
        filtersBar.onAction = { [weak self] in
            self?.filterButtonTapped()
        }
    }

    func configureChildViewController() {
        // Configure large title using the `hiddenScrollView` trick.
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.largeTitles) {
            hiddenScrollView.configureForLargeTitleWorkaround()
            // Adds the "hidden" scroll view to the root of the UIViewController for large title workaround.
            view.addSubview(hiddenScrollView)
            view.sendSubviewToBack(hiddenScrollView)
            hiddenScrollView.translatesAutoresizingMaskIntoConstraints = false
            view.pinSubviewToAllEdges(hiddenScrollView, insets: .zero)
            ordersViewController.delegate = self
        }

        // Add contentView to stackview
        let contentView = ordersViewController.view!
        addChild(ordersViewController)
        stackView.addArrangedSubview(contentView)
        ordersViewController.didMove(toParent: self)
    }

    /// Fetches the latest values of order-related experimental feature toggles and re configures navigation buttons.
    ///
    func fetchExperimentalTogglesAndConfigureNavigationButtons() {
        let group = DispatchGroup()
        var isOrderCreationEnabled = false

        group.enter()
        let orderCreationAction = AppSettingsAction.loadOrderCreationSwitchState { result in
            isOrderCreationEnabled = (try? result.get()) ?? false
            group.leave()
        }
        ServiceLocator.stores.dispatch(orderCreationAction)

        group.notify(queue: .main) { [weak self] in
            self?.configureNavigationButtons(isOrderCreationExperimentalToggleEnabled: isOrderCreationEnabled)
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
            case .failure:
                break
            }
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
    func createAddOrderItem(isOrderCreationEnabled: Bool) -> UIBarButtonItem {
        self.isOrderCreationEnabled = isOrderCreationEnabled

        let button = UIBarButtonItem(image: .plusBarButtonItemImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(presentOrderCreationFlow(sender:)))
        button.accessibilityTraits = .button

        if isOrderCreationEnabled {
            button.accessibilityLabel = NSLocalizedString("Choose new order type", comment: "Opens action sheet to choose a type of a new order")
            button.accessibilityIdentifier = "new-order-type-sheet-button"
        } else {
            button.accessibilityLabel = NSLocalizedString("Add simple payments order", comment: "Navigates to a screen to create a simple payments order")
            button.accessibilityIdentifier = "simple-payments-add-button"
        }
        return button
    }

    /// Presents Order Creation or Simple Payments flows.
    ///
    @objc func presentOrderCreationFlow(sender: UIBarButtonItem) {
        guard let navigationController = navigationController else {
            return
        }

        let coordinatingController = AddOrderCoordinator(siteID: siteID,
                                                         isOrderCreationEnabled: isOrderCreationEnabled,
                                                         sourceBarButtonItem: sender,
                                                         sourceNavigationController: navigationController)
        coordinatingController.onOrderCreated = { [weak self] order in
            guard let self = self else { return }

            self.dismiss(animated: true) {
                self.navigateToOrderDetail(order)
            }
        }
        coordinatingController.start()
    }

    /// Pushes an `OrderDetailsViewController` onto the navigation stack.
    ///
    private func navigateToOrderDetail(_ order: Order) {
        guard let orderViewController = OrderDetailsViewController.instantiatedViewControllerFromStoryboard() else { return }
        orderViewController.viewModel = OrderDetailsViewModel(order: order)

        // Cleanup navigation (remove new order flow views) before navigating to order details
        if let navigationController = navigationController, let indexOfSelf = navigationController.viewControllers.firstIndex(of: self) {
            let viewControllersIncludingSelf = navigationController.viewControllers[0...indexOfSelf]
            navigationController.setViewControllers(viewControllersIncludingSelf + [orderViewController], animated: true)
        } else {
            show(orderViewController, sender: self)
        }

        ServiceLocator.analytics.track(.orderOpen, withProperties: ["id": order.orderID, "status": order.status.rawValue])
    }
}

// MARK: - Constants
private extension OrdersRootViewController {
    enum Localization {
        static let defaultOrderListTitle = NSLocalizedString("Orders", comment: "The title of the Orders tab.")
        static let allOrdersEmptyStateMessage =
        NSLocalizedString("Waiting for your first order",
                          comment: "The message shown in the Orders → All Orders tab if the list is empty.")
        static let accessibilityLabelSearchOrders = NSLocalizedString("Search orders", comment: "Search Orders")
        static let accessibilityHintSearchOrders = NSLocalizedString(
            "Retrieves a list of orders that contain a given keyword.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to search orders."
        )
        static let accessibilityLabelAddSimplePayment = NSLocalizedString("Add simple payments order",
                                                                          comment: "Navigates to a screen to create a simple payments order")
    }
}
