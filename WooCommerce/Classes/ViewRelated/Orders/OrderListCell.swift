import UIKit

class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var paymentStatusLabel: PaddedLabel!
    @IBOutlet var shippingStatusLabel: PaddedLabel!

    var payStatusColor: UIColor = .clear
    var shipStatusColor: UIColor = .clear

    static let reuseIdentifier = "OrderListCell"

    func configureCell(order: Order) {
        let titleString = "#\(order.number) \(order.shippingAddress.firstName) \(order.shippingAddress.lastName)"
        let currencySymbol = order.currencySymbol
        let paymentStatusText = order.status.description

        titleLabel.text = titleString
        titleLabel.applyTitleStyle()
        totalLabel.text = "\(currencySymbol)\(order.total)"
        totalLabel.applyBodyStyle()
        paymentStatusLabel.text = paymentStatusText
        paymentStatusLabel.applyStatusStyle(for: order.status)
        shippingStatusLabel.text = ""
        // save the status colors found on the labels
        payStatusColor = paymentStatusLabel.backgroundColor!
        shipStatusColor = shippingStatusLabel.backgroundColor ?? .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // label background colors get reset upon selection, so re-assign status colors here
        paymentStatusLabel.backgroundColor = payStatusColor
        shippingStatusLabel.backgroundColor = shipStatusColor
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        // label background colors get reset upon highlight, so re-assign status colors here
        paymentStatusLabel.backgroundColor = payStatusColor
        shippingStatusLabel.backgroundColor = shipStatusColor
    }
}
