import UIKit

class ProductListTableViewCell: UITableViewCell {
    @IBOutlet private var verticalStackView: UIStackView!
    @IBOutlet private var fulfillButton: UIButton!

    static let reuseIdentifier = "ProductListTableViewCell"

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        backgroundColor = .white
    }
}

extension ProductListTableViewCell {
    func configure(with viewModel: OrderDetailsViewModel) {
        for subView in verticalStackView.arrangedSubviews {
            verticalStackView.removeArrangedSubview(subView)
        }

        for (index, item) in viewModel.items.enumerated() {
            let itemView = TwoColumnLabelView.makeFromNib()
            itemView.leftText = item.name
            itemView.rightText = item.quantity.description
            verticalStackView.insertArrangedSubview(itemView, at: index)
        }

        fulfillButton.setTitle(viewModel.fulfillTitle, for: .normal)
        fulfillButton.applyFilledRoundStyle()

        verticalStackView.setCustomSpacing(Constants.spacing, after: fulfillButton)
    }

    struct Constants {
        static let spacing = CGFloat(8.0)
    }
}
