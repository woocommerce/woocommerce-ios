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
        titleLabel.applyTitleStyle()
        totalLabel.text = "\(currencySymbol)\(orderTotal)"
        totalLabel.applyBodyStyle()
        paymentStatusLabel.text = order.status.description
        paymentStatusLabel.applyStatusStyle(for: order.status)
        shippingStatusLabel.text = ""
    }
}
