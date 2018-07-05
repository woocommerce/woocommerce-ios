import UIKit


class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var paymentStatusLabel: PaddedLabel!
    @IBOutlet var shippingStatusLabel: PaddedLabel!

    static let reuseIdentifier = "OrderListCell"

    func configureCell(order: OrderDetailsViewModel) {
        titleLabel.text = order.summaryTitle
        titleLabel.applyTitleStyle()
        totalLabel.text = order.totalValue
        totalLabel.applyBodyStyle()
        paymentStatusLabel.text = order.paymentStatus
        paymentStatusLabel.applyStatusStyle(for: order.orderStatusViewModel.orderStatus)
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
