import UIKit

class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var paymentStatusLabel: PaddedLabel!
    @IBOutlet var shippingStatusLabel: PaddedLabel!

    static let reuseIdentifier = "OrderListCell"

    func configureCell(order: Order) {
        let titleString = "#\(order.number) \(order.customer.firstName) \(order.customer.lastName)"
        let currencySymbol = order.currencySymbol
        let orderTotal = order.total
        titleLabel.text = titleString
        totalLabel.text = "\(currencySymbol)\(orderTotal)"
        paymentStatusLabel.text = order.status.description
        paymentStatusLabel.applyStatusStyle(order.status)
        shippingStatusLabel.text = ""
//        shippingStatusLabel.text = OrderStatus.cancelled.description
//        shippingStatusLabel.applyStatusStyle(.cancelled)
        accessoryType = .disclosureIndicator
    }
}
