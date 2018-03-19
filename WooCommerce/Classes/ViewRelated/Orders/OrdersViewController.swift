import UIKit

class OrdersViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var orders: Array<Order> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("Orders", comment: "Orders title")

        //FIXME: this is a hack so you can see a row working on the orders list table.
        let billingAddress = Address.init(firstName: "Thuy", lastName: "Copeland", company: "", address1: "500 Hollywood Blvd", address2: "", city: "Las Vegas", state: "NE", postcode: "90210", country: "US")
        let shippingAddress = Address.init(firstName: "Thuy", lastName: "Copeland", company: "", address1: "500 Hollywood Blvd", address2: "", city: "Las Vegas", state: "NE", postcode: "90210", country: "US")
        let customer = Customer.init(identifier: "1", firstName: "Thuy", lastName: "Copeland", email: nil, phone: nil, billingAddress: nil, shippingAddress: nil)
        let item = OrderItem.init(lineItemId: 1, name: "Belt", productID: 27, quantity: 1, sku: "", subtotal: "55.00", subtotalTax: "0.00", taxClass: "", total: "55.00", totalTax: "", variationID: 0)
        let order = Order.init(identifier: "190", number: "190", status: .processing, customer: customer, dateCreated: Date.init(), dateUpdated: Date.init(), shippingAddress: shippingAddress, billingAddress: billingAddress, items: [item], currency: "USD", total: 91.32, notes: [])

        orders = [order]
    }

    // MARK - Tableview 

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OrderListCell = tableView.dequeueReusableCell(withIdentifier: "OrderListCell", for: indexPath) as! OrderListCell
        cell.configureCell(order: orders[indexPath.row])

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Today"
    }
}
