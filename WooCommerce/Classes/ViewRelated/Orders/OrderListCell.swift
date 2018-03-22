import UIKit

class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var secondaryStatusLabel: UILabel!

    static let reuseIdentifier = "OrderListCell"

    func configureCell(order: Order) {
        let titleString = "#\(order.number) \(order.customer.firstName) \(order.customer.lastName)"
        let currencySymbol = order.currencySymbol
        let orderTotal = order.total
        titleLabel.text = titleString
        totalLabel.text = "\(currencySymbol)\(orderTotal)"
        statusLabel.text = order.status.description
        secondaryStatusLabel.text = ""
    }
}
