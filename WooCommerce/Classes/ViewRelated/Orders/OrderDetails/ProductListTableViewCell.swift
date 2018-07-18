import UIKit

class ProductListTableViewCell: UITableViewCell {
    @IBOutlet private var verticalStackView: UIStackView!
    @IBOutlet private var fulfillButton: UIButton!
    @IBOutlet private var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        fulfillButton.wooPrimaryButton()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension ProductListTableViewCell {
    func configure(with viewModel: OrderDetailsViewModel) {
        for subView in verticalStackView.arrangedSubviews {
            subView.removeFromSuperview()
        }

        for (index, item) in viewModel.items.enumerated() {
            let itemView = TwoColumnLabelView.makeFromNib()
            itemView.leftText = item.name
            itemView.rightText = item.quantity.description
            verticalStackView.insertArrangedSubview(itemView, at: index)
        }

        if viewModel.isProcessingPayment {
            fulfillButton.setTitle(viewModel.fulfillTitle, for: .normal)
        } else {
            containerView.isHidden = true
        }
    }
}
