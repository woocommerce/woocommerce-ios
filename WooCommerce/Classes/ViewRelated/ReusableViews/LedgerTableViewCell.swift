import UIKit

final class LedgerTableViewCell: UITableViewCell {
    @IBOutlet var verticalStackView: UIStackView!
    @IBOutlet var subtotalView: UIView!
    @IBOutlet private weak var subtotalLabel: UILabel!
    @IBOutlet private weak var subtotalValue: UILabel!
    private lazy var subtotalViews = RowGroup(containerView: subtotalView, label: subtotalLabel, value: subtotalValue)

    @IBOutlet private var discountView: UIView!
    @IBOutlet private weak var discountLabel: UILabel!
    @IBOutlet private weak var discountValue: UILabel!
    private lazy var discountViews = RowGroup(containerView: discountView, label: discountLabel, value: discountValue)

    @IBOutlet private weak var feesView: UIView!
    @IBOutlet private weak var feesLabel: UILabel!
    @IBOutlet private weak var feesValue: UILabel!
    private lazy var feesViews = RowGroup(containerView: feesView, label: feesLabel, value: feesValue)

    @IBOutlet private var shippingView: UIView!
    @IBOutlet private weak var shippingLabel: UILabel!
    @IBOutlet private weak var shippingValue: UILabel!
    private lazy var shippingViews = RowGroup(containerView: shippingView, label: shippingLabel, value: shippingValue)

    @IBOutlet private var taxesView: UIView!
    @IBOutlet private weak var taxesLabel: UILabel!
    @IBOutlet private weak var taxesValue: UILabel!
    private lazy var taxesViews = RowGroup(containerView: taxesView, label: taxesLabel, value: taxesValue)

    @IBOutlet weak var giftCardsView: UIView!
    @IBOutlet weak var giftCardsLabel: UILabel!
    @IBOutlet weak var giftCardsValue: UILabel!
    private lazy var giftCardsViews = RowGroup(containerView: giftCardsView, label: giftCardsLabel, value: giftCardsValue)

    @IBOutlet private var totalView: UIView!
    @IBOutlet private weak var totalLabel: UILabel!
    @IBOutlet private weak var totalValue: UILabel!
    @IBOutlet private weak var totalBottomConstraint: NSLayoutConstraint?
    private lazy var totalViews = RowGroup(containerView: totalView, label: totalLabel, value: totalValue)

    @IBOutlet weak var verticalStackViewTopConstraint: NSLayoutConstraint!
    struct RowGroup {
        let containerView: UIView
        let label: UILabel
        let value: UILabel

        func configure(title: String?, amount: String?, hidden: Bool) {
            label.text = title
            value.text = amount
            containerView.accessibilityLabel = "\(title ?? "") \(amount ?? "")"
            containerView.isHidden = hidden
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }

    /// Configure an order payment summary "table"
    ///
    func configure(with viewModel: OrderPaymentDetailsViewModel) {
        subtotalViews.configure(title: Titles.subtotalLabel, amount: viewModel.subtotalValue, hidden: viewModel.shouldHideSubtotal)
        discountViews.configure(title: viewModel.discountText, amount: viewModel.discountValue, hidden: viewModel.shouldHideDiscount)
        feesViews.configure(title: Titles.feesLabel, amount: viewModel.feesValue, hidden: viewModel.shouldHideFees)
        shippingViews.configure(title: Titles.shippingLabel, amount: viewModel.shippingValue, hidden: viewModel.shouldHideShipping)
        taxesViews.configure(title: Titles.taxesLabel, amount: viewModel.taxesValue, hidden: viewModel.shouldHideTaxes)
        giftCardsViews.configure(title: viewModel.giftCardsText, amount: viewModel.giftCardsValue, hidden: viewModel.shouldHideGiftCards)
        totalViews.configure(title: Titles.totalLabel, amount: viewModel.totalValue, hidden: false)
        configureAccessibility()
        configureLayout(with: viewModel)
    }

    /// Configure a refund details "table"
    ///
    func configure(with viewModel: RefundDetailsViewModel) {
        subtotalViews.configure(title: Titles.subtotal, amount: viewModel.itemSubtotal, hidden: false)
        discountViews.configure(title: nil, amount: nil, hidden: true)
        feesViews.configure(title: nil, amount: nil, hidden: true)
        shippingViews.configure(title: nil, amount: nil, hidden: true)
        taxesViews.configure(title: Titles.tax, amount: viewModel.taxSubtotal, hidden: taxesValue == nil)
        giftCardsViews.configure(title: nil, amount: nil, hidden: true)
        totalViews.configure(title: Titles.productsRefund, amount: viewModel.productsRefund, hidden: false)
        configureAccessibility()
    }
}

private extension LedgerTableViewCell {
    func configureLayout(with viewModel: OrderPaymentDetailsViewModel) {
        let shouldRemoveTopPadding = viewModel.shouldHideSubtotal &&
                                     viewModel.shouldHideDiscount &&
                                     viewModel.shouldHideFees &&
                                     viewModel.shouldHideShipping &&
                                     viewModel.shouldHideTaxes &&
                                     viewModel.shouldHideGiftCards

        if shouldRemoveTopPadding {
            verticalStackViewTopConstraint.constant = 0
        }
    }

    func configureAccessibility() {
        let visibleViews = [subtotalView,
                            discountView,
                            feesView,
                            shippingView,
                            taxesView,
                            giftCardsView,
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
        static let subtotalLabel = NSLocalizedString("Products",
                                                     comment: "Product Total label for payment view")
        static let feesLabel = NSLocalizedString("Custom Amounts",
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

    func getGiftCardsLabel() -> UILabel {
        return giftCardsLabel
    }

    func getGiftCardsValue() -> UILabel {
        return giftCardsValue
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
        giftCardsLabel.applyBodyStyle()
        giftCardsValue.applyBodyStyle()
        totalLabel.applyHeadlineStyle()
        totalValue.applyHeadlineStyle()
    }
}
