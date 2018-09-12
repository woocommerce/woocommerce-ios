import UIKit


class OrderListCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet var paymentStatusLabel: PaddedLabel!


    func configureCell(viewModel: OrderDetailsViewModel) {
        titleLabel.text = viewModel.summaryTitle
        titleLabel.applyHeadlineStyle()
        totalLabel.text = viewModel.totalValue
        totalLabel.applyBodyStyle()
        paymentStatusLabel.text = viewModel.paymentStatus
        paymentStatusLabel.applyStatusStyle(for: viewModel.orderStatusViewModel.orderStatus)
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

        action()

        paymentStatusLabel.backgroundColor = paymentColor
    }
}
