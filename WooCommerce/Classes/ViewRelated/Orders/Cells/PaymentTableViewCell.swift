import UIKit

class PaymentTableViewCell: UITableViewCell {
    @IBOutlet var verticalStackView: UIStackView!
    @IBOutlet var subtotalView: UIView!
    @IBOutlet public weak var subtotalLabel: UILabel!
    @IBOutlet public weak var subtotalValue: UILabel!

    @IBOutlet public var discountView: UIView!
    @IBOutlet public weak var discountLabel: UILabel!
    @IBOutlet public weak var discountValue: UILabel!

    @IBOutlet var shippingView: UIView!
    @IBOutlet public weak var shippingLabel: UILabel!
    @IBOutlet public weak var shippingValue: UILabel!

    @IBOutlet public var taxesView: UIView!
    @IBOutlet public weak var taxesLabel: UILabel!
    @IBOutlet public weak var taxesValue: UILabel!

    @IBOutlet var totalView: UIView!
    @IBOutlet public weak var totalLabel: UILabel!
    @IBOutlet public weak var totalValue: UILabel!

    @IBOutlet var footerView: UIView!
    @IBOutlet public weak var separatorLine: UIView!
    @IBOutlet public weak var footerValue: UILabel!


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
