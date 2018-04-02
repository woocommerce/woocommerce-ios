import UIKit

class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var paymentStatusLabel: PaddedLabel!
    @IBOutlet var shippingStatusLabel: PaddedLabel!

    static let reuseIdentifier = "OrderListCell"

    func configureCell(order: Order) {
        let titleString = "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
        let currencySymbol = order.currencySymbol
        titleLabel.text = titleString
        titleLabel.applyTitleStyle()
        totalLabel.text = "\(currencySymbol)\(order.totalString)"
        totalLabel.applyBodyStyle()
        paymentStatusLabel.text = order.status.description
        paymentStatusLabel.applyStatusStyle(order.status)
        shippingStatusLabel.text = ""
    }
}
