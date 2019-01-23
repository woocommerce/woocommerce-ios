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

    @IBOutlet private var footerView: UIView?
    @IBOutlet private weak var separatorLine: UIView?
    @IBOutlet private weak var footerLabel: UILabel?
    @IBOutlet private weak var totalBottomConstraint: NSLayoutConstraint?

    public var footerText: String? {
        get {
            return footerLabel?.text
        }
        set {
            guard newValue != nil, newValue?.isEmpty == false else {
                separatorLine?.removeFromSuperview()
                footerLabel?.removeFromSuperview()
                footerView?.removeFromSuperview()
                totalBottomConstraint?.constant = 0
                return
            }
            footerLabel?.text = newValue
        }
    }

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

        footerLabel?.text = nil
        footerLabel?.applyFootnoteStyle()
        separatorLine?.backgroundColor = StyleManager.cellSeparatorColor
    }
}
