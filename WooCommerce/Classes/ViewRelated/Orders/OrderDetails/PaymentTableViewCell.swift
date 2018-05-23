import UIKit

class PaymentTableViewCell: UITableViewCell {
    static let reuseIdentifier = "PaymentTableViewCell"
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
        contentView.addSubview(subtotalView)

        if detailsViewModel.hasDiscount,
        let discountLabelText = discountLabel,
        let discountValueText = discountValue {
            let discountView = TwoColumnLabelView.makeFromNib()
            discountView.configure(leftText: discountLabelText, rightText: discountValueText)
            contentView.addSubview(discountView)
        }

        let shippingView = TwoColumnLabelView.makeFromNib()
        shippingView.configure(leftText: shippingLabel, rightText: shippingValue)
        contentView.addSubview(shippingView)

        if detailsViewModel.hasTaxes,
        let taxesLabelText = taxesLabel,
        let taxesValueText = taxesValue {
            let taxesView = TwoColumnLabelView.makeFromNib()
            taxesView.configure(leftText: taxesLabelText, rightText: taxesValueText)
            contentView.addSubview(taxesView)
        }

        let totalView = TwoColumnLabelView.makeFromNib()
        totalView.configureWithTitleStyle(leftText: totalLabel, rightText: totalValue)
        contentView.addSubview(totalView)
    }
}
