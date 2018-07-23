import UIKit


/// Displays the list of Products associated to an Order.
///
class ProductListTableViewCell: UITableViewCell {
    @IBOutlet private var verticalStackView: UIStackView!
    @IBOutlet private var fulfillButton: UIButton!
    @IBOutlet private var actionContainerView: UIView!

    var onFullfillTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        fulfillButton.applyPrimaryButtonStyle()
        fulfillButton.addTarget(self, action: #selector(fulfillWasPressed), for: .touchUpInside)
        verticalStackView.setCustomSpacing(Constants.spacing, after: fulfillButton)
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

        fulfillButton.setTitle(viewModel.fulfillTitle, for: .normal)
        actionContainerView.isHidden = viewModel.isProcessingPayment == false
    }

    @IBAction func fulfillWasPressed() {
        onFullfillTouchUp?()
    }

    struct Constants {
        static let spacing = CGFloat(8.0)
    }
}
