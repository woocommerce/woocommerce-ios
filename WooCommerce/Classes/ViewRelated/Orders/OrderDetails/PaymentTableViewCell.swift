import UIKit

class PaymentTableViewCell: UITableViewCell {
    let verticalStackView = UIStackView()

    static let reuseIdentifier = "PaymentTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        verticalStackView.axis = .vertical
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(verticalStackView)

        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            verticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.topConstant),
            verticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: Constants.bottomConstant)
            ])
    }
}

extension PaymentTableViewCell {
    func configure(with detailsViewModel: OrderDetailsViewModel) {
        let subtotalLabel = detailsViewModel.subtotalLabel
        let subtotalValue = detailsViewModel.subtotalValue
        let discountLabel = detailsViewModel.discountLabel
        let discountValue = detailsViewModel.discountValue
        let shippingLabel = detailsViewModel.shippingLabel
        let shippingValue = detailsViewModel.shippingValue
        let taxesLabel = detailsViewModel.taxesLabel
        let taxesValue = detailsViewModel.taxesValue
        let totalLabel = detailsViewModel.totalLabel
        let totalValue = detailsViewModel.totalValue

        let subtotalView = TwoColumnLabelView.makeFromNib()
        subtotalView.configure(leftText: subtotalLabel, rightText: subtotalValue)
        verticalStackView.addArrangedSubview(subtotalView)

        if detailsViewModel.hasDiscount,
        let discountLabelText = discountLabel,
        let discountValueText = discountValue {
            let discountView = TwoColumnLabelView.makeFromNib()
            discountView.configure(leftText: discountLabelText, rightText: discountValueText)
            verticalStackView.addArrangedSubview(discountView)
        }

        let shippingView = TwoColumnLabelView.makeFromNib()
        shippingView.configure(leftText: shippingLabel, rightText: shippingValue)
        verticalStackView.addArrangedSubview(shippingView)

        if detailsViewModel.hasTaxes,
        let taxesLabelText = taxesLabel,
        let taxesValueText = taxesValue {
            let taxesView = TwoColumnLabelView.makeFromNib()
            taxesView.configure(leftText: taxesLabelText, rightText: taxesValueText)
            verticalStackView.addArrangedSubview(taxesView)
        }

        let totalView = TwoColumnLabelView.makeFromNib()
        totalView.configureWithTitleStyle(leftText: totalLabel, rightText: totalValue)
        verticalStackView.addArrangedSubview(totalView)

        let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: 1))
        separatorView.backgroundColor = StyleManager.sectionTitleColor
        verticalStackView.addArrangedSubview(separatorView)
    }

    struct Constants {
        static let topConstant = CGFloat(14)
        static let bottomConstant = CGFloat(-14)
    }
}
