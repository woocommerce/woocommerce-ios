import UIKit

class PaymentTableViewCell: UITableViewCell {
    @IBOutlet var verticalStackView: UIStackView!
    @IBOutlet var subtotalView: UIView!
    @IBOutlet private weak var subtotalLabel: UILabel!
    @IBOutlet private weak var subtotalValue: UILabel!

    @IBOutlet var discountView: UIView!
    @IBOutlet private weak var discountLabel: UILabel!
    @IBOutlet private weak var discountValue: UILabel!

    @IBOutlet var shippingView: UIView!
    @IBOutlet private weak var shippingLabel: UILabel!
    @IBOutlet private weak var shippingValue: UILabel!

    @IBOutlet var taxesView: UIView!
    @IBOutlet private weak var taxesLabel: UILabel!
    @IBOutlet private weak var taxesValue: UILabel!

    @IBOutlet var totalView: UIView!
    @IBOutlet private weak var totalLabel: UILabel!
    @IBOutlet private weak var totalValue: UILabel!

    @IBOutlet var footerView: UIView!
    @IBOutlet private weak var separatorLine: UIView!
    @IBOutlet private weak var footerValue: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        subtotalLabel.applyBodyStyle()
        subtotalValue.applyBodyStyle()
        discountLabel.applyBodyStyle()
        discountValue.applyBodyStyle()
        shippingLabel.applyBodyStyle()
        shippingValue.applyBodyStyle()
        taxesLabel.applyBodyStyle()
        taxesValue.applyBodyStyle()
        totalLabel.applyHeadlineStyle()
        totalValue.applyHeadlineStyle()
        footerValue.applyFootnoteStyle()
    }
}

extension PaymentTableViewCell {
    func configure(with detailsViewModel: OrderDetailsViewModel) {
        subtotalLabel.text = detailsViewModel.subtotalLabel
        subtotalValue.text = detailsViewModel.subtotalValue

        discountLabel.text = detailsViewModel.discountLabel
        discountValue.text = detailsViewModel.discountValue
        discountView.isHidden = detailsViewModel.discountValue == nil

        shippingLabel.text = detailsViewModel.shippingLabel
        shippingValue.text = detailsViewModel.shippingValue

        taxesLabel.text = detailsViewModel.taxesLabel
        taxesValue.text = detailsViewModel.taxesValue
        taxesView.isHidden = detailsViewModel.taxesValue == nil

        totalLabel.text = detailsViewModel.totalLabel
        totalValue.text = detailsViewModel.totalValue

        separatorLine.backgroundColor = StyleManager.cellSeparatorColor
        footerValue.text = detailsViewModel.paymentSummary
    }
}
