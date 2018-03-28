import UIKit
import Gridicons

class OrdersViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var orders = [Order]()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()

        //FIXME: this is a hack so you can see a row working on the orders list table.
        let billingAddress = Address(firstName: "Thuy", lastName: "Copeland", company: "", address1: "500 Hollywood Blvd", address2: "", city: "Las Vegas", state: "NE", postcode: "90210", country: "US")
        let shippingAddress = Address(firstName: "Thuy", lastName: "Copeland", company: "", address1: "500 Hollywood Blvd", address2: "", city: "Las Vegas", state: "NE", postcode: "90210", country: "US")
        let customer = Customer(identifier: "1", firstName: "Thuy", lastName: "Copeland", email: nil, phone: nil, billingAddress: billingAddress, shippingAddress: shippingAddress)
        let item = OrderItem(lineItemId: 1, name: "Belt", productID: 27, quantity: 1, sku: "", subtotal: "55.00", subtotalTax: "0.00", taxClass: "", total: "55.00", totalTax: "", variationID: 0)
        let order = Order(identifier: "190", number: "190", status: .processing, customer: customer, dateCreated: Date.init(), dateUpdated: Date.init(), shippingAddress: shippingAddress, billingAddress: billingAddress, items: [item], currency: "USD", total: 91.32, notes: [])

        orders = [order]
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
}

extension OrdersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderListCell.reuseIdentifier, for: indexPath) as! OrderListCell
        cell.configureCell(order: orders[indexPath.row])

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // FIXME: this is hard-coded data
        return NSLocalizedString("Today", comment: "Title for header section")
    }
}
