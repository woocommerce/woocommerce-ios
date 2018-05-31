import UIKit

class ProductListTableViewCell: UITableViewCell {
    var verticalStackView = UIStackView()

    static let reuseIdentifier = "ProductListTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fillProportionally
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(verticalStackView)

        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            verticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.defaultPadding),
            verticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: Constants.negativePadding)
            ])
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        backgroundColor = .white
    }
}

extension ProductListTableViewCell {
    func configure(with viewModel: OrderDetailsViewModel) {
        if verticalStackView.arrangedSubviews.count > 0 {
            for subView in verticalStackView.arrangedSubviews {
                verticalStackView.removeArrangedSubview(subView)
            }
        }
        for item in viewModel.items {
            let itemView = TwoColumnLabelView.makeFromNib()
            itemView.configure(leftText: item.name, rightText: item.quantity.description)
            verticalStackView.addArrangedSubview(itemView)
        }
        let spacerView = IntrinsicHeightView()
        spacerView.height = 8.0
        verticalStackView.addArrangedSubview(spacerView)
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
