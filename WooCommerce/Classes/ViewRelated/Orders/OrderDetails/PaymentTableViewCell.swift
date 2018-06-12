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

        let subtotal = buildSubtotalView(with: detailsViewModel)
        let subtotalView = subtotal.0
        subtotalView.isHidden = subtotal.1
        verticalStackView.addArrangedSubview(subtotalView)

        let discount = buildDiscountView(with: detailsViewModel)
        let discountView = discount.0
        discountView.isHidden = discount.1
        verticalStackView.addArrangedSubview(discountView)

        let shipping = buildShippingView(with: detailsViewModel)
        let shippingView = shipping.0
        shippingView.isHidden = shipping.1
        verticalStackView.addArrangedSubview(shippingView)

        let taxes = buildTaxesView(with: detailsViewModel)
        let taxesView = taxes.0
        taxesView.isHidden = taxes.1
        verticalStackView.addArrangedSubview(taxesView)

        let total = buildTotalView(with: detailsViewModel)
        let totalView = total.0
        totalView.isHidden = total.1
        verticalStackView.addArrangedSubview(totalView)

        let footnoteView = buildFootnoteView(with: detailsViewModel)
        verticalStackView.addArrangedSubview(footnoteView)
    }

    func buildSubtotalView(with detailsViewModel: OrderDetailsViewModel) -> (TwoColumnLabelView, Bool)  {
        let subtotalLabel = detailsViewModel.subtotalLabel
        let subtotalValue = detailsViewModel.subtotalValue
        let isHidden = false

        let subtotalView = TwoColumnLabelView.makeFromNib()
        subtotalView.configure(leftText: subtotalLabel, rightText: subtotalValue)

        return (subtotalView, isHidden)
    }

    func buildDiscountView(with detailsViewModel: OrderDetailsViewModel) -> (TwoColumnLabelView, Bool) {
        let discountLabel = detailsViewModel.discountLabel
        let discountValue = detailsViewModel.discountValue
        let isHidden = discountValue == nil

        let discountView = TwoColumnLabelView.makeFromNib()
        discountView.configure(leftText: discountLabel, rightText: discountValue)
        verticalStackView.addArrangedSubview(discountView)

        return (discountView, isHidden)
    }

    func buildShippingView(with detailsViewModel: OrderDetailsViewModel) -> (TwoColumnLabelView, Bool) {
        let shippingLabel = detailsViewModel.shippingLabel
        let shippingValue = detailsViewModel.shippingValue

        let shippingView = TwoColumnLabelView.makeFromNib()
        shippingView.configure(leftText: shippingLabel, rightText: shippingValue)

        return (shippingView, false)
    }

    func buildTaxesView(with detailsViewModel: OrderDetailsViewModel) -> (TwoColumnLabelView, Bool) {
        let taxesLabel = detailsViewModel.taxesLabel
        let taxesValue = detailsViewModel.taxesValue
        let isHidden = taxesValue == nil

        let taxesView = TwoColumnLabelView.makeFromNib()
        taxesView.configure(leftText: taxesLabel, rightText: taxesValue)

        return (taxesView, isHidden)
    }

    func buildTotalView(with detailsViewModel: OrderDetailsViewModel) -> (TwoColumnLabelView, Bool) {
        let totalLabel = detailsViewModel.totalLabel
        let totalValue = detailsViewModel.totalValue

        let totalView = TwoColumnLabelView.makeFromNib()
        totalView.configureWithTitleStyle(leftText: totalLabel, rightText: totalValue)
        return (totalView, false)
    }

    func buildFootnoteView(with detailsViewModel: OrderDetailsViewModel) -> FootnoteView {
        let footnoteView = FootnoteView.makeFromNib()
        footnoteView.footnote = detailsViewModel.paymentSummary
        footnoteView.separatorColor = StyleManager.cellSeparatorColor
        return footnoteView
    }

    struct Constants {
        static let topConstant = CGFloat(14)
    }
}
