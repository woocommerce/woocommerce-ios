import UIKit
import Gridicons
import Yosemite
import CocoaLumberjack


/// OrdersViewController: Displays the list of Orders associated to the active Store / Account.
///
class OrdersViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Properties

    private var orders = [Order]()
    private var filterResults = [Order]()
    private var isUsingFilterAction = false

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()


    // MARK: - Computed Properties

    private var displaysNoResults: Bool {
        return filterResults.isEmpty && isUsingFilterAction
    }

    private var siteID: Int? {
        return StoresManager.shared.sessionManager.defaultStoreID
    }



    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.title = NSLocalizedString("Orders", comment: "Orders title")
        tabBarItem.image = Gridicon.iconOfType(.pages)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if orders.isEmpty {
            syncOrders()
        }
    }


    // MARK: - User Interface Initialization

    func configureNavigation() {
        title = NSLocalizedString("Orders", comment: "Orders title")
        let rightBarButton = UIBarButtonItem(image: Gridicon.iconOfType(.menus),
                                             style: .plain,
                                             target: self,
                                             action: #selector(rightButtonTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)

        // Don't show the Order title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let nib = UINib(nibName: NoResultsTableViewCell.reuseIdentifier, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: NoResultsTableViewCell.reuseIdentifier)
        tableView.refreshControl = refreshControl
    }

    // MARK: - Actions

    @objc func rightButtonTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Dismiss the action sheet"), style: .cancel)
        actionSheet.addAction(dismissAction)

        let allAction = UIAlertAction(title: NSLocalizedString("All", comment: "All filter title"), style: .default) { [weak self ] action in
            self?.isUsingFilterAction = false
            self?.tableView.reloadData()
        }
        actionSheet.addAction(allAction)

        for status in OrderStatusViewModel.allOrderStatuses {
            let action = UIAlertAction(title: status.description, style: .default) { action in
                self.filterAction(status)
            }
            actionSheet.addAction(action)
        }
        present(actionSheet, animated: true)
    }

    @objc func pullToRefresh(sender: UIRefreshControl) {
        clearOrders()
        syncOrders()
    }

    func filterAction(_ status: OrderStatus) {
        if case .custom(_) = status {
            filterByAllCustomStatuses()
            return
        }

        filterResults = orders.filter { order in
            return order.status.description.contains(status.description)
        }

        isUsingFilterAction = filterResults.count != orders.count
        tableView.reloadData()
    }

    func filterByAllCustomStatuses() {
        var customOrders = [Order]()
        for order in orders {
            if case .custom(_) = order.status {
                customOrders.append(order)
            }
        }
        filterResults = customOrders
        isUsingFilterAction = filterResults.count != orders.count
        tableView.reloadData()
    }
}


// MARK: - Sync'ing Helpers
//
private extension OrdersViewController {
    func syncOrders() {
        let action = OrderAction.retrieveOrders(siteID: siteID) { [weak self] (orders, error) in
            self?.refreshControl.endRefreshing()
            guard error == nil else {
                if let error = error {
                    DDLogError("⛔️ Error synchronizing orders: \(error)")
                }
                return
            }
            guard let orders = orders else {
                return
            }
            self?.orders = orders
            self?.tableView.reloadData()
        }

        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        refreshControl.beginRefreshing()
        StoresManager.shared.dispatch(action)
    }

    func clearOrders() {
        orders = []
        isUsingFilterAction = false
        tableView.reloadData()
    }
}


// MARK: - Convenience Methods
//
private extension OrdersViewController {

    func orderAtIndexPath(_ indexPath: IndexPath) -> Order {
        return isUsingFilterAction ? filterResults[indexPath.row] : orders[indexPath.row]
    }

    func detailsViewModel(at indexPath: IndexPath) -> OrderDetailsViewModel? {
        guard let siteID = siteID else {
            return nil
        }

        return OrderDetailsViewModel(siteID: siteID, order: orderAtIndexPath(indexPath))
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension OrdersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isUsingFilterAction == true {
            if filterResults.isEmpty {
                return Constants.filterResultsNotFoundRowCount
            }
            return filterResults.count
        }
        return orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !displaysNoResults else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NoResultsTableViewCell.reuseIdentifier, for: indexPath) as! NoResultsTableViewCell
            cell.configure(text: NSLocalizedString("No results found. Clear the filter to try again.", comment: "Displays message to user when no filter results were found."))
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderListCell.reuseIdentifier, for: indexPath) as? OrderListCell,
            let viewModel = detailsViewModel(at: indexPath)
            else {
                fatalError()
        }

        cell.configureCell(order: viewModel)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // FIXME: this is hard-coded data. Will fix when WordPressShared date helpers are available to make fuzzy dates.
        return NSLocalizedString("Today", comment: "Title for header section")
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension OrdersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard displaysNoResults == false else {
            return
        }

        performSegue(withIdentifier: Constants.orderDetailsSegue, sender: detailsViewModel(at: indexPath))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let singleOrderViewController = segue.destination as? OrderDetailsViewController, let viewModel = sender as? OrderDetailsViewModel else {
            return
        }

        singleOrderViewController.viewModel = viewModel
    }
}


// MARK: - Constants
//
private extension OrdersViewController {
    struct Constants {
        static let rowHeight = CGFloat(86)
        static let orderDetailsSegue = "ShowOrderDetailsViewController"
        static let filterResultsNotFoundRowCount = 1
    }
}
