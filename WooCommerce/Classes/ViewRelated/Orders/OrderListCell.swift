import UIKit

class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var statusLabel: PaddedLabel!
    @IBOutlet var secondaryStatusLabel: PaddedLabel!

    static let reuseIdentifier = "OrderListCell"

    func configureCell(order: Order) {
        let titleString = "#\(order.number) \(order.customer.firstName) \(order.customer.lastName)"
        let currencySymbol = order.currencySymbol
        let orderTotal = order.total
        titleLabel.text = titleString
        totalLabel.text = "\(currencySymbol)\(orderTotal)"
        statusLabel.text = order.status.description
        statusLabel.applyStatusStyle(order.status)
        secondaryStatusLabel.text = OrderStatus.cancelled.description
        secondaryStatusLabel.applyStatusStyle(.cancelled)
    }
}
