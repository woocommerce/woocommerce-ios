import UIKit
import Gridicons

class OrdersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var orders = [Order]()
    var filterResults = [Order]()
    private var isUsingFilterAction = false
    var displaysNoResults: Bool {
        return filterResults.isEmpty && isUsingFilterAction
    }

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

    func loadOrderNotes(basicOrder: Order) -> Order {
        let resource = "order-notes-\(basicOrder.number)"
        guard let path = Bundle.main.url(forResource: resource, withExtension: "json") else {
            return basicOrder
        }

        do {
            let json = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            let orderNotesFromJson = try decoder.decode([OrderNote].self, from: json)
            var order = basicOrder
            order.notes = orderNotesFromJson
            return order
        } catch {
            print("error:\(error)")
            return basicOrder
        }
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
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        let nib = UINib(nibName: NoResultsTableViewCell.reuseIdentifier, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: NoResultsTableViewCell.reuseIdentifier)
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

// MARK: UITableViewDataSource
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
        let order = orderAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderListCell.reuseIdentifier, for: indexPath) as! OrderListCell
        cell.configureCell(order: order)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // FIXME: this is hard-coded data. Will fix when WordPressShared date helpers are available to make fuzzy dates.
        return NSLocalizedString("Today", comment: "Title for header section")
    }

    func orderAtIndexPath(_ indexPath: IndexPath) -> Order {
        return isUsingFilterAction ? filterResults[indexPath.row] : orders[indexPath.row]
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
        guard displaysNoResults == false else {
            return
        }

        if segue.identifier == Constants.orderDetailsSegue {
            if let singleOrderViewController = segue.destination as? OrderDetailsViewController {
                let indexPath = sender as! IndexPath
                let order = orderAtIndexPath(indexPath)
                let singleOrder = loadSingleOrder(basicOrder: order)
                let detailedOrder = loadOrderNotes(basicOrder: singleOrder)
                singleOrderViewController.order = detailedOrder
            }
        }
    }
}

// MARK: Constants
//
extension OrdersViewController {
    struct Constants {
        static let rowHeight = CGFloat(86)
        static let orderDetailsSegue = "ShowOrderDetailsViewController"
        static let filterResultsNotFoundRowCount = 1
    }
}
