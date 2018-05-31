import UIKit

class ProductListTableViewCell: UITableViewCell {
    @IBOutlet private weak var verticalStackView: UIStackView!

    static let reuseIdentifier = "ProductListTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension ProductListTableViewCell {
    func configure(with viewModel: OrderDetailsViewModel) {
        // Don't re-draw the subviews on an existing table cell
        if verticalStackView.subviews.count > 0 {
            return
        }
        for item in viewModel.items {
            let itemView = TwoColumnLabelView.makeFromNib()
            itemView.configure(leftText: item.name, rightText: item.quantity.description)
            verticalStackView.addArrangedSubview(itemView)
        }
        let fulfillButton = IntrinsicHeightButton()
        fulfillButton.height = 48.0
        fulfillButton.setTitle(viewModel.fulfillTitle, for: .normal)
        fulfillButton.applyFilledRoundStyle()
        verticalStackView.addArrangedSubview(fulfillButton)
        NSLayoutConstraint.activate([
            fulfillButton.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor, constant: Constants.defaultPadding),
            fulfillButton.trailingAnchor.constraint(equalTo: verticalStackView.trailingAnchor, constant: Constants.negativePadding)
            ])
        fulfillButton.layoutIfNeeded()
    }

    struct Constants {
        static let negativePadding = CGFloat(-16)
        static let defaultPadding = CGFloat(16)
    }
}
