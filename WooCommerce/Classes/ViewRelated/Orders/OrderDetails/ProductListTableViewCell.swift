import UIKit

class ProductListTableViewCell: UITableViewCell {
    @IBOutlet private var verticalStackView: UIStackView!
    @IBOutlet private var fulfillButton: UIButton!
    @IBOutlet private var actionContainerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        fulfillButton.applyPrimaryButtonStyle()
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
            actionContainerView.isHidden = false
        } else {
            actionContainerView.isHidden = true
        }
    }
}
