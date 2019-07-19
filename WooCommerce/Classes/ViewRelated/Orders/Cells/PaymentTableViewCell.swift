import UIKit

final class PaymentTableViewCell: UITableViewCell {
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

    func configure(with viewModel: OrderPaymentDetailsViewModel) {
        subtotalLabel.text = Titles.subtotalLabel
        subtotalValue.text = viewModel.subtotalValue

        discountLabel.text = viewModel.discountText
        discountValue.text = viewModel.discountValue
        discountView.isHidden = viewModel.discountValue == nil

        shippingLabel.text = Titles.shippingLabel
        shippingValue.text = viewModel.shippingValue

        taxesLabel.text = Titles.taxesLabel
        taxesValue.text = viewModel.taxesValue
        taxesView.isHidden = taxesValue == nil

        totalLabel.text = Titles.totalLabel
        totalValue.text = viewModel.totalValue

        footerText = viewModel.paymentSummary

        accessibilityElements = [subtotalLabel as Any,
                                 subtotalValue as Any,
                                 discountLabel as Any,
                                 discountValue as Any,
                                 shippingLabel as Any,
                                 shippingValue as Any,
                                 taxesLabel as Any,
                                 taxesValue as Any,
                                 totalLabel as Any,
                                 totalValue as Any]

        if let footerText = footerText {
            accessibilityElements?.append(footerText)
        }
    }
}


private extension PaymentTableViewCell {
    enum Titles {
        static let subtotalLabel = NSLocalizedString("Subtotal",
                                                     comment: "Subtotal label for payment view")
        static let shippingLabel = NSLocalizedString("Shipping",
                                                     comment: "Shipping label for payment view")
        static let taxesLabel = NSLocalizedString("Taxes",
                                                  comment: "Taxes label for payment view")
        static let totalLabel = NSLocalizedString("Total",
                                                  comment: "Total label for payment view")
    }
}
