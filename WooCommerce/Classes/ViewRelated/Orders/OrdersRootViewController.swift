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

    /// Lets us know if the store is ready to receive in person payments
    ///
    private let inPersonPaymentsUseCase = CardPresentPaymentsOnboardingUseCase()

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
                filtersBar.setNumberOfFilters(filters.numberOfActiveFilters)
                orderListViewModel.updateFilters(filters: filters)
            }
        }
    }

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
        observeInPersonPaymentsStoreState()
    }

    override func viewWillAppear(_ animated: Bool) {
        // Needed in ViewWillAppear because this View Controller is never recreated.
        fetchSimplePaymentsExperimentalToggleAndConfigureNavigationButtons()
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
        //TODO-5243: add event for tracking the filter tapped
        let viewModel = FilterOrderListViewModel(filters: filters)
        let filterOrderListViewController = FilterListViewController(viewModel: viewModel, onFilterAction: { [weak self] filters in
            //TODO-5243: add event for tracking filter list show
            self?.filters = filters
        }, onClearAction: {
            //TODO-5243: add event for tracking clear action
        }, onDismissAction: {
            //TODO-5243: add event for tracking dismiss action
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
    /// Simple Payments: Depends on the local feature flag, experimental feature toggle and the inPersonPayments state.
    ///
    func configureNavigationButtons(isSimplePaymentsExperimentalToggleEnabled: Bool) {
        let shouldShowSimplePaymentsButton: Bool = {
            let isInPersonPaymentsConfigured = inPersonPaymentsUseCase.state == .completed
            return isSimplePaymentsExperimentalToggleEnabled && isInPersonPaymentsConfigured
        }()
        let buttons: [UIBarButtonItem?] = [
            createSearchBarButtonItem(),
            shouldShowSimplePaymentsButton ? createAddSimplePaymentsOrderItem() : nil
        ]
        navigationItem.rightBarButtonItems = buttons.compactMap { $0 }
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

    /// Observes the store `InPersonPayments` state and reconfigure navigation buttons appropriately.
    ///
    func observeInPersonPaymentsStoreState() {
        inPersonPaymentsUseCase.$state
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.fetchSimplePaymentsExperimentalToggleAndConfigureNavigationButtons()
            }
            .store(in: &subscriptions)
        inPersonPaymentsUseCase.refresh()
    }

    /// Fetches the latest value of the SimplePayments experimental feature toggle and re configures navigation buttons.
    ///
    func fetchSimplePaymentsExperimentalToggleAndConfigureNavigationButtons() {
        let action = AppSettingsAction.loadSimplePaymentsSwitchState { [weak self] result in
            let isEnabled = (try? result.get()) ?? false
            self?.configureNavigationButtons(isSimplePaymentsExperimentalToggleEnabled: isEnabled)
        }
        ServiceLocator.stores.dispatch(action)
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

    /// Create a `UIBarButtonItem` to be used as a way to create a new simple payments order.
    ///
    func createAddSimplePaymentsOrderItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(image: .plusBarButtonItemImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(presentSimplePaymentsAmountController))
        button.accessibilityTraits = .button
        button.accessibilityLabel = Localization.accessibilityLabelAddSimplePayment
        button.accessibilityIdentifier = "simple-payments-add-button"
        return button
    }

    /// Presents `SimplePaymentsAmountHostingController`.
    ///
    @objc private func presentSimplePaymentsAmountController() {
        let viewModel = SimplePaymentsAmountViewModel(siteID: siteID)
        viewModel.onOrderCreated = { [weak self] order in
            guard let self = self else { return }

            self.dismiss(animated: true) {
                self.navigateToOrderDetail(order)
            }
        }

        let viewController = SimplePaymentsAmountHostingController(viewModel: viewModel)
        let navigationController = WooNavigationController(rootViewController: viewController)
        present(navigationController, animated: true)

        analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowStarted())
    }

    /// Pushes an `OrderDetailsViewController` onto the navigation stack.
    ///
    private func navigateToOrderDetail(_ order: Order) {
        guard let orderViewController = OrderDetailsViewController.instantiatedViewControllerFromStoryboard() else { return }
        orderViewController.viewModel = OrderDetailsViewModel(order: order)
        show(orderViewController, sender: self)

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
