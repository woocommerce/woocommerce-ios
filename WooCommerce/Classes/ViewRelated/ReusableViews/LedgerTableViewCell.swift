import UIKit

final class LedgerTableViewCell: UITableViewCell {
    @IBOutlet var verticalStackView: UIStackView!
    @IBOutlet var subtotalView: UIView!
    @IBOutlet private weak var subtotalLabel: UILabel!
    @IBOutlet private weak var subtotalValue: UILabel!

    @IBOutlet private var discountView: UIView!
    @IBOutlet private weak var discountLabel: UILabel!
    @IBOutlet private weak var discountValue: UILabel!

    @IBOutlet private weak var feesView: UIView!
    @IBOutlet private weak var feesLabel: UILabel!
    @IBOutlet private weak var feesValue: UILabel!

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
        configureSubtotal(label: Titles.subtotalLabel, value: viewModel.subtotalValue)
        configureDiscount(label: viewModel.discountText, value: viewModel.discountValue, hidden: viewModel.shouldHideDiscount)
        configureFees(label: Titles.feesLabel, value: viewModel.feesValue, hidden: viewModel.shouldHideFees)
        configureShipping(label: Titles.shippingLabel, value: viewModel.shippingValue, hidden: false)
        configureTaxes(label: Titles.taxesLabel, value: viewModel.taxesValue, hidden: viewModel.shouldHideTaxes)
        configureTotal(label: Titles.totalLabel, value: viewModel.totalValue)
        configureAccessibility()
    }

    /// Configure a refund details "table"
    ///
    func configure(with viewModel: RefundDetailsViewModel) {
        configureSubtotal(label: Titles.subtotal, value: viewModel.itemSubtotal)
        configureDiscount(label: nil, value: nil, hidden: true)
        configureFees(label: nil, value: nil, hidden: true)
        configureShipping(label: nil, value: nil, hidden: true)
        configureTaxes(label: Titles.tax, value: viewModel.taxSubtotal, hidden: taxesValue == nil)
        configureTotal(label: Titles.productsRefund, value: viewModel.productsRefund)
        configureAccessibility()
    }

    private func configureSubtotal(label: String, value: String) {
        subtotalLabel.text = label
        subtotalValue.text = value
        subtotalView.accessibilityLabel = "\(label) \(value)"
    }

    private func configureDiscount(label: String?, value: String?, hidden: Bool) {
        discountLabel.text = label
        discountValue.text = value
        discountView.accessibilityLabel = "\(label ?? "") \(value ?? "")"
        discountView.isHidden = hidden
    }

    private func configureFees(label: String?, value: String?, hidden: Bool) {
        feesLabel.text = label
        feesValue.text = value
        feesView.accessibilityLabel = "\(label ?? "") \(value ?? "")"
        feesView.isHidden = hidden
    }

    private func configureShipping(label: String?, value: String?, hidden: Bool) {
        shippingLabel.text = label
        shippingValue.text = value
        shippingView.accessibilityLabel = "\(label ?? "") \(value ?? "")"
        shippingView.isHidden = hidden
    }

    private func configureTaxes(label: String, value: String?, hidden: Bool) {
        taxesLabel.text = label
        taxesValue.text = value
        taxesView.accessibilityLabel = "\(label) \(value ?? "")"
        taxesView.isHidden = hidden
    }

    private func configureTotal(label: String, value: String) {
        totalLabel.text = label
        totalValue.text = value
        totalView.accessibilityLabel = "\(label) \(value)"
    }

    private func configureAccessibility() {
        let visibleViews = [subtotalView,
                            discountView,
                            feesView,
                            shippingView,
                            taxesView,
                            totalView].filter({
                                $0?.isHidden == false
                            })
                            .map({
                                $0 as Any
                            })

        accessibilityElements = visibleViews
    }
}


private extension LedgerTableViewCell {
    enum Titles {
        static let subtotalLabel = NSLocalizedString("Product Total",
                                                     comment: "Product Total label for payment view")
        static let feesLabel = NSLocalizedString("Fees",
                                                     comment: "Fees label for payment view")
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

    func getFeesLabel() -> UILabel {
        return feesLabel
    }

    func getFeesValue() -> UILabel {
        return feesValue
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
        feesLabel.applyBodyStyle()
        feesValue.applyBodyStyle()
        shippingLabel.applyBodyStyle()
        shippingValue.applyBodyStyle()
        taxesLabel.applyBodyStyle()
        taxesValue.applyBodyStyle()
        totalLabel.applyHeadlineStyle()
        totalValue.applyHeadlineStyle()
    }
}
