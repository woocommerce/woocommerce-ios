import UIKit
import Gridicons

class OrdersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var orders = [Order]()
    var searchResults = [Order]()
    let searchController = UISearchController(searchResultsController: nil)
    var isUsingFilterAction = false

    func loadSampleOrders() -> [Order] {
        guard let path = Bundle.main.url(forResource: "order-list", withExtension: "json") else {
            return []
        }

        let json = try! Data(contentsOf: path)
        let decoder = JSONDecoder()
        return try! decoder.decode([Order].self, from: json)
    }

    func loadSingleOrder(basicOrder: Order) -> Order {
        let resource = "order-\(basicOrder.number)"
        if let path = Bundle.main.url(forResource: resource, withExtension: "json") {
            do {
                let json = try Data(contentsOf: path)
                let decoder = JSONDecoder()
                let orderFromJson = try decoder.decode(Order.self, from: json)

                return orderFromJson
            } catch {
                print("error:\(error)")
            }
        }
        return basicOrder
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.title = NSLocalizedString("Orders", comment: "Orders title")
        tabBarItem.image = Gridicon.iconOfType(.pages)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        configureSearch()
        orders = loadSampleOrders()
    }

    func configureNavigation() {
        title = NSLocalizedString("Orders", comment: "Orders title")
        let rightBarButton = UIBarButtonItem(image: Gridicon.iconOfType(.listUnordered),
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
        tableView.estimatedRowHeight = 86
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = NSLocalizedString("Search all orders", comment: "Search placeholder text")
        searchController.searchBar.sizeToFit()

        // This may need set app-wide in the future. Not yet.
        searchController.searchBar.barTintColor = tableView.backgroundColor
        searchController.searchBar.layer.borderWidth = 1
        searchController.searchBar.layer.borderColor = tableView.backgroundColor?.cgColor

        // add it to the table header, which leaves us room for pull-to-refresh control
        tableView.tableHeaderView = searchController.searchBar
        tableView.contentOffset = CGPoint(x: 0.0, y: searchController.searchBar.frame.size.height)
    }

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

        for status in OrderStatus.allOrderStatuses {
            let action = UIAlertAction(title: status.description, style: .default) { action in
                self.filterAction(status)
            }
            actionSheet.addAction(action)
        }
        present(actionSheet, animated: true)
    }

    func filterAction(_ status: OrderStatus) {
        switch status {
        case .processing:
            fallthrough
        case .pending:
            fallthrough
        case .failed:
            fallthrough
        case .canceled:
            fallthrough
        case .completed:
            fallthrough
        case .onHold:
            fallthrough
        case .refunded:
            searchResults = orders.filter { order in
                return order.status.description.contains(status.description)
            }
            isUsingFilterAction = searchResults.count != orders.count
            tableView.reloadData()
        default:
            filterByAllCustomStatuses()
        }
    }

    func filterByAllCustomStatuses() {
        var customOrders = [Order]()
        for order in orders {
            switch order.status {
            case .processing:
                continue
            case .pending:
                continue
            case .failed:
                continue
            case .canceled:
                continue
            case .completed:
                continue
            case .onHold:
                continue
            case .refunded:
                continue
            default:
                customOrders.append(order)
            }
        }
        searchResults = customOrders
        isUsingFilterAction = searchResults.count != orders.count
        tableView.reloadData()
    }

    // MARK: Search bar
    func isFiltering() -> Bool {
        let usingSearch = searchController.isActive && !searchBarIsEmpty()
        let usingFilter = isUsingFilterAction
        return usingSearch || usingFilter
    }

    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
}

// MARK: UITableViewDataSource
//
extension OrdersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            if searchResults.count == 0 {
                return Constants.noSearchResultsRow
            }
            return searchResults.count
        }
        return orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let order = orderAtIndexPath(indexPath)
        guard let singleOrder = order else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "NoResultsCell")
            cell.textLabel?.text = "No results found. Clear the filter or search bar to try again."
            cell.textLabel?.numberOfLines = 0
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderListCell.reuseIdentifier, for: indexPath) as! OrderListCell
        cell.configureCell(order: singleOrder)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // FIXME: this is hard-coded data. Will fix when WordPressShared date helpers are available to make fuzzy dates.
        return NSLocalizedString("Today", comment: "Title for header section")
    }

    func orderAtIndexPath(_ indexPath: IndexPath) -> Order? {
        if isFiltering() {
            if indexPath.row > searchResults.count - 1 {
                return nil
            }
            return searchResults[indexPath.row]
        }
        return orders[indexPath.row]
    }
}

// MARK: UITableViewDelegate
//
extension OrdersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: Constants.orderDetailsSegue, sender: indexPath)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.orderDetailsSegue {
            if let singleOrderViewController = segue.destination as? OrderDetailsViewController {
                let indexPath = sender as! IndexPath
                let anOrder = orderAtIndexPath(indexPath)
                if let basicOrder = anOrder {
                    let singleOrder = loadSingleOrder(basicOrder: basicOrder)
                    singleOrderViewController.order = singleOrder
                }
            }
        }
    }
}

// MARK: UISearchResultsUpdating
//
extension OrdersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else {
            return
        }
        // TODO: filter search results properly
        searchResults = orders.filter { order in
            return order.shippingAddress.firstName.lowercased().contains(searchString.lowercased())
        }
        tableView.reloadData()
    }
}

// MARK: UISearchBarDelegate
//
extension OrdersViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.resignFirstResponder()
        tableView.reloadData()
    }
}

// MARK: Constants
//
extension OrdersViewController {
    struct Constants {
        static let orderDetailsSegue = "ShowOrderDetailsViewController"
        static let noSearchResultsRow = 1
    }
}
