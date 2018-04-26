import UIKit
import Gridicons

class OrdersViewController: UIViewController {
    struct Constants {
        static let groupedFirstSectionHeaderHeight: CGFloat = 32.0
        static let groupedSectionHeaderHeight: CGFloat = 12.0
    }

    @IBOutlet weak var tableView: UITableView!
    var orders = [Order]()
    var searchResults = [Order]()
    let searchController = UISearchController(searchResultsController: nil)
    var showSearchResults = false

    func loadSampleOrders() -> [Order] {
        guard let path = Bundle.main.url(forResource: "data", withExtension: "json") else {
            return []
        }

        let json = try! Data(contentsOf: path)
        let decoder = JSONDecoder()
        return try! decoder.decode([Order].self, from: json)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
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

        let allAction = UIAlertAction(title: NSLocalizedString("All", comment: "All filter title"), style: .default) { action in
            // display all of the orders
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
            default:
                print("next: filter the table data and display!")
        }
    }

    // MARK: Search bar
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
}

extension OrdersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return searchResults.count
        }
        return orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderListCell.reuseIdentifier, for: indexPath) as! OrderListCell
        let order = orderAtIndexPath(indexPath)
        cell.configureCell(order: order)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // FIXME: this is hard-coded data. Will fix when WordPressShared date helpers are available to make fuzzy dates.
        return NSLocalizedString("Today", comment: "Title for header section")
    }

    func orderAtIndexPath(_ indexPath: IndexPath) -> Order {
        return showSearchResults ? searchResults[indexPath.row] : orders[indexPath.row]
    }
}

extension OrdersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return Constants.groupedFirstSectionHeaderHeight
        }
        return Constants.groupedSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension OrdersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else {
            return
        }
        // TODO: filter search results properly
        searchResults = orders.filter { order in
            return order.shippingAddress.firstName.lowercased().contains(searchString.lowercased())
        }
        showSearchResults = searchResults.count > 0
        tableView.reloadData()
    }
}

extension OrdersViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        showSearchResults = searchBar.text?.isEmpty == false
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if showSearchResults {
            showSearchResults = false
            searchController.searchBar.text = nil
        }
        searchController.searchBar.resignFirstResponder()
        tableView.reloadData()
    }
}
