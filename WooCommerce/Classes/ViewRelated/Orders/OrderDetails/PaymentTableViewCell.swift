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
            verticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
    }
}

extension PaymentTableViewCell {
    func configure(with detailsViewModel: OrderDetailsViewModel) {
        // Don't re-draw the subviews on an existing table cell
        if verticalStackView.subviews.count > 0 {
            return
        }
        let subtotalView = buildSubtotalView(with: detailsViewModel)
        verticalStackView.addArrangedSubview(subtotalView)

        let discountView = buildDiscountView(with: detailsViewModel)
        if let discountSubview = discountView {
            verticalStackView.addArrangedSubview(discountSubview)
        }

        let shippingView = buildShippingView(with: detailsViewModel)
        verticalStackView.addArrangedSubview(shippingView)

        let taxesView = buildTaxesView(with: detailsViewModel)
        if let taxesSubview = taxesView {
            verticalStackView.addArrangedSubview(taxesSubview)
        }

        let totalView = buildTotalView(with: detailsViewModel)
        verticalStackView.addArrangedSubview(totalView)

        let footnoteView = buildFootnoteView(with: detailsViewModel)
        verticalStackView.addArrangedSubview(footnoteView)
    }

    func buildSubtotalView(with detailsViewModel: OrderDetailsViewModel) -> TwoColumnLabelView {
        let subtotalLabel = detailsViewModel.subtotalLabel
        let subtotalValue = detailsViewModel.subtotalValue

        let subtotalView = TwoColumnLabelView.makeFromNib()
        subtotalView.configure(leftText: subtotalLabel, rightText: subtotalValue)

        return subtotalView
    }

    func buildDiscountView(with detailsViewModel: OrderDetailsViewModel) -> TwoColumnLabelView? {
        let discountLabel = detailsViewModel.discountLabel
        let discountValue = detailsViewModel.discountValue

        if detailsViewModel.hasDiscount,
            let discountLabelText = discountLabel,
            let discountValueText = discountValue {

            let discountView = TwoColumnLabelView.makeFromNib()
            discountView.configure(leftText: discountLabelText, rightText: discountValueText)
            verticalStackView.addArrangedSubview(discountView)

            return discountView
        }

        return nil
    }

    func buildShippingView(with detailsViewModel: OrderDetailsViewModel) -> TwoColumnLabelView {
        let shippingLabel = detailsViewModel.shippingLabel
        let shippingValue = detailsViewModel.shippingValue

        let shippingView = TwoColumnLabelView.makeFromNib()
        shippingView.configure(leftText: shippingLabel, rightText: shippingValue)

        return shippingView
    }

    func buildTaxesView(with detailsViewModel: OrderDetailsViewModel) -> TwoColumnLabelView? {
        let taxesLabel = detailsViewModel.taxesLabel
        let taxesValue = detailsViewModel.taxesValue

        if detailsViewModel.hasTaxes,
            let taxesLabelText = taxesLabel,
            let taxesValueText = taxesValue {
            let taxesView = TwoColumnLabelView.makeFromNib()
            taxesView.configure(leftText: taxesLabelText, rightText: taxesValueText)

            return taxesView
        }
        return nil
    }

    func buildTotalView(with detailsViewModel: OrderDetailsViewModel) -> TwoColumnLabelView {
        let totalLabel = detailsViewModel.totalLabel
        let totalValue = detailsViewModel.totalValue

        let totalView = TwoColumnLabelView.makeFromNib()
        totalView.configureWithTitleStyle(leftText: totalLabel, rightText: totalValue)
        return totalView
    }

    func buildFootnoteView(with detailsViewModel: OrderDetailsViewModel) -> FootnoteView {
        let footnoteView = FootnoteView.makeFromNib()
        footnoteView.configure(footnoteText: detailsViewModel.paymentSummary, borderColor: StyleManager.cellSeparatorColor)
        return footnoteView
    }

    struct Constants {
        static let topConstant = CGFloat(14)
    }
}
