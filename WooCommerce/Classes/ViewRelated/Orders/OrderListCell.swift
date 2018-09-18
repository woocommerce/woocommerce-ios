import UIKit


class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var paymentStatusLabel: PaddedLabel!


    func configureCell(order: OrderDetailsViewModel) {
        titleLabel.text = order.summaryTitle
        titleLabel.applyHeadlineStyle()
        totalLabel.text = order.totalValue
        totalLabel.applyBodyStyle()
        paymentStatusLabel.text = order.paymentStatus
        paymentStatusLabel.applyStatusStyle(for: order.orderStatusViewModel.orderStatus)
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

    override func prepareForReuse() {
        super.prepareForReuse()
        paymentStatusLabel.layer.borderColor = UIColor.clear.cgColor
    }

    func preserveLabelColors(action: () -> Void) {
        let paymentColor = paymentStatusLabel.backgroundColor

        action()

        paymentStatusLabel.backgroundColor = paymentColor
    }
}
