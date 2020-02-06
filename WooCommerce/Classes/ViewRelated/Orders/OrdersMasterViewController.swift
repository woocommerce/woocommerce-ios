
import UIKit
import struct Yosemite.OrderStatus
import struct Yosemite.Note

/// The main Orders view controller that is shown when the Orders tab is accessed.
///
/// TODO This should contain the tabs "Processing" and "All Orders".
///
final class OrdersMasterViewController: UIViewController {

    private lazy var analytics = ServiceLocator.analytics

    private lazy var viewModel = OrdersMasterViewModel(statusFilterChanged: { [weak self] (status: OrderStatus?) in
        self?.statusFilterChanged(status: status)
    })

    /// The view controller that shows the list of Orders.
    ///
    private var ordersViewController: OrdersViewController?

    init() {
        super.init(nibName: Self.nibName, bundle: nil)

        title = NSLocalizedString("Orders", comment: "The title of the Orders tab.")

        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.activate()

        configureNavigationButtons()
        configureOrdersViewController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.syncOrderStatuses()
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

    /// Called when the ViewModel's `statusFilter` changed.
    ///
    private func statusFilterChanged(status: OrderStatus?) {
        ordersViewController?.statusFilter = status
        navigationItem.title = status.titleForNavigationItem
    }

    /// Show the list of Order statuses can be filtered with.
    ///
    @objc private func displayFiltersAlert() {
        analytics.track(.ordersListFilterTapped)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(FilterAction.dismiss)
        actionSheet.addDefaultActionWithTitle(FilterAction.displayAll) { [weak self] _ in
            self?.viewModel.statusFilter = nil
        }

        for orderStatus in viewModel.currentSiteStatuses {
            actionSheet.addDefaultActionWithTitle(orderStatus.name) { [weak self] _ in
                self?.viewModel.statusFilter = orderStatus
            }
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.barButtonItem = navigationItem.rightBarButtonItem
        popoverController?.sourceView = self.view

        present(actionSheet, animated: true)
    }

    /// Shows `SearchViewController`.
    ///
    @objc private func displaySearchOrders() {
        guard let storeID = viewModel.storeID else {
            return
        }

        analytics.track(.ordersListSearchTapped)

        let searchViewController = SearchViewController<OrderTableViewCell, OrderSearchUICommand>(storeID: storeID,
                                                                                                  command: OrderSearchUICommand(),
                                                                                                  cellType: OrderTableViewCell.self)
        let navigationController = WooNavigationController(rootViewController: searchViewController)

        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - OrdersViewControllerDelegate

extension OrdersMasterViewController: OrdersViewControllerDelegate {
    func ordersViewControllerWillSynchronizeOrders(_ viewController: OrdersViewController) {
        viewModel.syncOrderStatuses()
    }

    func ordersViewControllerRequestsToClearStatusFilter(_ viewController: OrdersViewController) {
        viewModel.statusFilter = nil
    }
}

// MARK: - Initialization and Loading (Not Reusable)

private extension OrdersMasterViewController {
    /// Set up properties for `self` as a root tab bar controller.
    ///
    func configureTabBarItem() {
        tabBarItem.title = title
        tabBarItem.image = .pagesImage
        tabBarItem.accessibilityIdentifier = "tab-bar-orders-item"
    }

    /// For `viewDidLoad` only, set up `navigationItem` buttons.
    ///
    func configureNavigationButtons() {
        navigationItem.leftBarButtonItem = createSearchBarButtonItem()
        navigationItem.rightBarButtonItem = createFilterBarButtonItem()

        removeNavigationBackBarButtonText()
    }

    /// For `viewDidLoad` only, initialize and set up bindings for `self.ordersViewController`.
    ///
    func configureOrdersViewController() {
        ordersViewController = createAndAttachOrdersViewController()
        ordersViewController?.delegate = self
    }
}

// MARK: - Creators

private extension OrdersMasterViewController {
    /// Create a `UIBarButtonItem` to be used as the filter button on the top-right.
    ///
    func createFilterBarButtonItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(image: .filterImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(displayFiltersAlert))
        button.accessibilityTraits = .button
        button.accessibilityLabel = NSLocalizedString("Filter orders", comment: "Filter the orders list.")
        button.accessibilityHint = NSLocalizedString(
            "Filters the order list by payment status.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to filter the order list."
        )
        button.accessibilityIdentifier = "order-filter-button"

        return button
    }

    /// Create a `UIBarButtonItem` to be used as the search button on the top-left.
    ///
    func createSearchBarButtonItem() -> UIBarButtonItem {
        let button = UIBarButtonItem(image: .searchImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(displaySearchOrders))
        button.accessibilityTraits = .button
        button.accessibilityLabel = NSLocalizedString("Search orders", comment: "Search Orders")
        button.accessibilityHint = NSLocalizedString(
            "Retrieves a list of orders that contain a given keyword.",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to search orders."
        )
        button.accessibilityIdentifier = "order-search-button"

        return button
    }

    /// Creates an `OrdersViewController` and attaches its view to `self.view`.
    ///
    func createAndAttachOrdersViewController() -> OrdersViewController? {
        guard let ordersViewController = OrdersViewController.instantiatedViewControllerFromStoryboard(),
            let ordersView = ordersViewController.view else {
                return nil
        }

        ordersView.translatesAutoresizingMaskIntoConstraints = false

        add(ordersViewController)
        view.addSubview(ordersView)
        ordersView.pinSubviewToAllEdges(view)
        ordersViewController.didMove(toParent: self)

        return ordersViewController
    }

    enum FilterAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let displayAll = NSLocalizedString(
            "All",
            comment: "Name of the All filter on the Order List screen - it means all orders will be displayed."
        )
    }
}

// MARK: - Optional<OrderStatus> Extension

private extension Optional where Wrapped == OrderStatus {
    /// A localized title to use as the `OrdersMasterViewController`'s navigation title.
    ///
    var titleForNavigationItem: String {
        guard let filterName = self?.name else {
            return NSLocalizedString(
                "Orders",
                comment: "Title that appears on top of the Order List screen when there is no filter applied to the list (plural form of the word Order)."
            )
        }

        return String.localizedStringWithFormat(
            NSLocalizedString(
                "Orders: %@",
                comment: "Title that appears on top of the Order List screen when a filter is applied. It reads: Orders: {name of filter}"
            ),
            filterName
        )
    }
}
