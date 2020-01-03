import UIKit

final class LedgerTableViewCell: UITableViewCell {
    @IBOutlet var verticalStackView: UIStackView!
    @IBOutlet var subtotalView: UIView!
    @IBOutlet private weak var subtotalLabel: UILabel!
    @IBOutlet private weak var subtotalValue: UILabel!

    @IBOutlet private var discountView: UIView!
    @IBOutlet private weak var discountLabel: UILabel!
    @IBOutlet private weak var discountValue: UILabel!

    @IBOutlet private var shippingView: UIView!
    @IBOutlet private weak var shippingLabel: UILabel!
    @IBOutlet private weak var shippingValue: UILabel!

    @IBOutlet private var taxesView: UIView!
    @IBOutlet private weak var taxesLabel: UILabel!
    @IBOutlet private weak var taxesValue: UILabel!

    @IBOutlet private var totalView: UIView!
    @IBOutlet private weak var totalLabel: UILabel!
    @IBOutlet private weak var totalValue: UILabel!
    @IBOutlet private weak var totalBottomConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }

    /// Configure an order payment summary "table"
    ///
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

        accessibilityElements = [subtotalLabel as Any,
                                 subtotalValue as Any,
                                 discountLabel as Any,
                                 discountValue as Any,
                                 shippingLabel as Any,
                                 shippingValue as Any,
                                 taxesLabel as Any,
                                 taxesValue as Any,
                                 totalLabel as Any,
                                 totalValue as Any
                                ]
    }

    /// Configure a refund details "table"
    ///
    func configure(with viewModel: RefundDetailsViewModel) {
        subtotalLabel.text = Titles.subtotal
        subtotalValue.text = viewModel.itemSubtotal

        discountLabel.text = nil
        discountValue.text = nil
        discountView.isHidden = true

        shippingLabel.text = nil
        shippingValue.text = nil
        shippingView.isHidden = true

        taxesLabel.text = Titles.tax
        taxesValue.text = viewModel.taxSubtotal
        taxesView.isHidden = taxesValue == nil

        totalLabel.text = Titles.productsRefund
        totalValue.text = viewModel.productsRefund
    }
}


private extension LedgerTableViewCell {
    enum Titles {
        static let subtotalLabel = NSLocalizedString("Product Total",
                                                     comment: "Product Total label for payment view")
        static let shippingLabel = NSLocalizedString("Shipping",
                                                     comment: "Shipping label for payment view")
        static let taxesLabel = NSLocalizedString("Taxes",
                                                  comment: "Taxes label for payment view")
        static let totalLabel = NSLocalizedString("Order Total",
                                                  comment: "Order Total label for payment view")

        static let subtotal = NSLocalizedString("Subtotal",
                                                comment: "Subtotal label for a refund details view")
        static let tax = NSLocalizedString("Tax",
                                           comment: "Tax label for a refund details view")
        static let productsRefund = NSLocalizedString("Products Refund",
                                                      comment: "Label for computed value `product refunds + taxes = subtotal`.")
    }
}


// Indirectly expose outlets for tests
extension LedgerTableViewCell {
    func getSubtotalLabel() -> UILabel {
        return subtotalLabel
    }

    func getSubtotalValue() -> UILabel {
        return subtotalValue
    }

    func getDiscountLabel() -> UILabel {
        return discountLabel
    }

    func getDiscountValue() -> UILabel {
        return discountValue
    }

    func getShippingLabel() -> UILabel {
        return shippingLabel
    }

    func getShippingValue() -> UILabel {
        return shippingValue
    }

    func getTaxesLabel() -> UILabel {
        return taxesLabel
    }

    func getTaxesValue() -> UILabel {
        return taxesValue
    }

    func getTotalLabel() -> UILabel {
        return totalLabel
    }

    func getTotalValue() -> UILabel {
        return totalValue
    }
}

// MARK: - Private Methods
//
private extension LedgerTableViewCell {
    /// Setup: Cell background
    ///
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    /// Setup: Labels
    ///
    func configureLabels() {
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
    }
}
