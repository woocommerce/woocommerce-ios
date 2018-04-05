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
        var paymentStatusText: String
        if order.status == .custom {
            paymentStatusText = order.statusString
        } else {
            paymentStatusText = order.status.description
        }
        titleLabel.text = titleString
        titleLabel.applyTitleStyle()
        totalLabel.text = "\(currencySymbol)\(order.totalString)"
        totalLabel.applyBodyStyle()
        paymentStatusLabel.text = paymentStatusText
        paymentStatusLabel.applyStatusStyle(for: order.status)
        shippingStatusLabel.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        let payStatusColor = paymentStatusLabel.backgroundColor
        let shipStatusColor = shippingStatusLabel.backgroundColor
        super.setSelected(selected, animated: animated)
        paymentStatusLabel.backgroundColor = payStatusColor
        shippingStatusLabel.backgroundColor = shipStatusColor
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let payStatusColor = paymentStatusLabel.backgroundColor
        let shipStatusColor = shippingStatusLabel.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        paymentStatusLabel.backgroundColor = payStatusColor
        shippingStatusLabel.backgroundColor = shipStatusColor
    }
}
