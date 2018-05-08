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
        totalLabel.text = "\(currencySymbol)\(order.totalString)"
        totalLabel.applyBodyStyle()
        paymentStatusLabel.text = paymentStatusText
        paymentStatusLabel.applyStatusStyle(for: order.status)
        shippingStatusLabel.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        preserveLabelColors {
            super.setSelected(selected, animated: animated)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        preserveLabelColors {
            super.setHighlighted(highlighted, animated: animated)
        }
    }

    func preserveLabelColors(action: () -> Void) {
        let paymentColor = paymentStatusLabel.backgroundColor
        let shippingColor = shippingStatusLabel.backgroundColor

        action()

        paymentStatusLabel.backgroundColor = paymentColor
        shippingStatusLabel.backgroundColor = shippingColor
    }
}
