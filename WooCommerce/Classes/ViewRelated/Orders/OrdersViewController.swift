import UIKit
import Gridicons

class OrdersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var orders = [Order]()
    var searchResults = [Order]()
    let searchController = UISearchController(searchResultsController: nil)
    var showSearchResults = false

    func loadJson() -> Array<Order> {
        if let path = Bundle.main.url(forResource: "real-data-orders-list", withExtension: "json") {
            do {
                let json = try Data(contentsOf: path)
                let decoder = JSONDecoder()
                let orders = try decoder.decode([Order].self, from: json)
                return orders
            } catch {
                print("error:\(error)")
            }
        }
        return []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureSearch()
        orders = loadJson()
    }

    func configureNavigation() {
        navigationController?.navigationBar.topItem?.title = NSLocalizedString("Orders", comment: "Orders title")
        let rightBarButton = UIBarButtonItem(image: Gridicon.iconOfType(.listUnordered),
                                             style: .plain,
                                             target: self,
                                             action: #selector(rightButtonTapped))
        rightBarButton.tintColor = UIColor.white
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }

    func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = NSLocalizedString("Search all orders", comment: "Search placeholder text")
//        searchController.searchBar.sizeToFit() // get the proper size for displaying in table header

        // MARK: This may need set app-wide in the future. Not yet.
        searchController.searchBar.barTintColor = tableView.backgroundColor
        searchController.searchBar.layer.borderWidth = 1
        searchController.searchBar.layer.borderColor = tableView.backgroundColor?.cgColor

        // add it to the table header, which leaves us room for pull-to-refresh control
        tableView.tableHeaderView = searchController.searchBar
        tableView.contentOffset = CGPoint(x: 0.0, y: searchController.searchBar.frame.size.height)
    }

    @objc func rightButtonTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.active.wooCommerceBrandColor
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Dismiss the action sheet"), style: .cancel) { action in
            // no action needed when dismissing
        }
        actionSheet.addAction(dismissAction)

        let allAction = UIAlertAction(title: NSLocalizedString("All", comment: "All filter title"), style: .default) { action in
            // display all of the orders
        }
        actionSheet.addAction(allAction)

        for status in OrderStatus.array {
            let action = UIAlertAction(title: status.description, style: .default) { action in
                self.filterAction(status)
            }
            actionSheet.addAction(action)
        }

        present(actionSheet, animated: true) {
            // things to do after presenting the action sheet
        }
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

    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        searchResults = orders.filter({ (order : Order) -> Bool in
            if let firstName = order.customer?.firstName {
                return firstName.lowercased().contains(searchText.lowercased())
            } else {
                return false
            }
        })
        tableView.reloadData()
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
        if isFiltering() {
            cell.configureCell(order: searchResults[indexPath.row])
        } else {
            cell.configureCell(order: orders[indexPath.row])
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // FIXME: this is hard-coded data. Will fix when WordPressShared date helpers are available to make fuzzy dates.
        return NSLocalizedString("Today", comment: "Title for header section")
    }
}

extension OrdersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 32
        }
        return 12
    }
}

extension OrdersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // TODO: filter search results
    }
}

extension OrdersViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text == nil || searchBar.text == "" {
            showSearchResults = false
        } else {
            showSearchResults = true
        }

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
