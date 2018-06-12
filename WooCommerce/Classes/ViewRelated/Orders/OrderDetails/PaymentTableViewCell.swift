import UIKit

class PaymentTableViewCell: UITableViewCell {
    let verticalStackView = UIStackView()

    static let reuseIdentifier = "PaymentTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension PaymentTableViewCell {
    func configureVerticalStackView() {
        verticalStackView.axis = .vertical
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(verticalStackView)

        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            verticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.topConstant),
            verticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
    }

    func configure(with detailsViewModel: OrderDetailsViewModel) {
        verticalStackView.removeFromSuperview()
        configureVerticalStackView()

        let subtotalView = TwoColumnLabelView.makeFromNib()
        subtotalView.configure(leftText: detailsViewModel.subtotalLabel, rightText: detailsViewModel.subtotalValue)
        verticalStackView.addArrangedSubview(subtotalView)

        let discountView = TwoColumnLabelView.makeFromNib()
        discountView.configure(leftText: detailsViewModel.discountLabel, rightText: detailsViewModel.discountValue)
        verticalStackView.addArrangedSubview(discountView)
        discountView.isHidden = detailsViewModel.discountValue == nil

        let shippingView = TwoColumnLabelView.makeFromNib()
        shippingView.configure(leftText: detailsViewModel.shippingLabel, rightText: detailsViewModel.shippingValue)
        verticalStackView.addArrangedSubview(shippingView)

        let taxesView = TwoColumnLabelView.makeFromNib()
        taxesView.configure(leftText: detailsViewModel.taxesLabel, rightText: detailsViewModel.taxesValue)
        verticalStackView.addArrangedSubview(taxesView)
        taxesView.isHidden = detailsViewModel.taxesValue == nil

        let totalView = TwoColumnLabelView.makeFromNib()
        totalView.configureWithTitleStyle(leftText: detailsViewModel.totalLabel, rightText: detailsViewModel.totalValue)
        verticalStackView.addArrangedSubview(totalView)

        let footnoteView = FootnoteView.makeFromNib()
        footnoteView.footnote = detailsViewModel.paymentSummary
        footnoteView.separatorColor = StyleManager.cellSeparatorColor
        verticalStackView.addArrangedSubview(footnoteView)
    }

    struct Constants {
        static let topConstant = CGFloat(14)
    }
}
