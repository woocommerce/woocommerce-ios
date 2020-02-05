
import UIKit
import struct Yosemite.OrderStatus

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

        tabBarItem.title = title
        tabBarItem.image = .pagesImage
        tabBarItem.accessibilityIdentifier = "tab-bar-orders-item"
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.activate()

        navigationItem.rightBarButtonItem = createFilterBarButtonItem()

        guard let ordersViewController = OrdersViewController.instantiatedViewControllerFromStoryboard(),
            let ordersView = ordersViewController.view else {
            return
        }

        ordersView.translatesAutoresizingMaskIntoConstraints = false

        add(ordersViewController)
        view.addSubview(ordersView)
        ordersView.pinSubviewToAllEdges(view)
        ordersViewController.didMove(toParent: self)

        self.ordersViewController = ordersViewController

        ordersViewController.willSynchronizeOrders = { [weak self] in
            self?.viewModel.syncOrderStatuses()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.syncOrderStatuses()
    }

    /// Called when the ViewModel's `statusFilter` changed.
    ///
    private func statusFilterChanged(status: OrderStatus?) {
        ordersViewController?.statusFilter = status
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

    private func createFilterBarButtonItem() -> UIBarButtonItem {
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

    enum FilterAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let displayAll = NSLocalizedString(
            "All",
            comment: "Name of the All filter on the Order List screen - it means all orders will be displayed."
        )
    }
}
