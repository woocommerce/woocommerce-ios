import UIKit

final class ShippingLabelSummaryTableViewCell: UITableViewCell {

    @IBOutlet private weak var mainStackView: UIStackView!

    @IBOutlet private weak var subtotalTitle: UILabel!
    @IBOutlet private weak var subtotalBody: UILabel!

    @IBOutlet private weak var discountView: UIStackView!
    @IBOutlet private weak var discountTitle: UILabel!
    @IBOutlet private weak var discountImage: UIImageView!
    @IBOutlet private weak var discountBody: UILabel!

    @IBOutlet private weak var orderTotalTitle: UILabel!
    @IBOutlet private weak var orderTotalBody: UILabel!

    @IBOutlet private weak var orderCompleteTitle: UILabel!
    @IBOutlet private weak var orderCompleteSwitch: UISwitch!

    @IBOutlet private weak var separator: UIImageView!
    @IBOutlet private weak var button: ButtonActivityIndicator!

    /// Extra stack views for package rates when there are more than one label.
    ///
    private var packageRatesStackViews: [UIStackView] = []

    /// Boolean indicating if the Switch is On or Off.
    ///
    var isOn: Bool {
        get {
            return orderCompleteSwitch.isOn
        }
        set {
            orderCompleteSwitch.isOn = newValue
        }
    }

    /// Closure to be executed whenever the Discount View is tapped
    ///
    private var onDiscountTouchUp: (() -> Void)?

    /// Closure to be executed whenever the Switch is flipped
    ///
    private var onSwitchChange: ((Bool) -> Void)?

    /// Closure to be executed whenever the Button is tapped
    ///
    private var onButtonTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureStyle()
        configureLabels()
        configureSwitch()
        configureButton()
        discountView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(discountViewTapped)))
    }

    func configure(state: ShippingLabelFormStepTableViewCell.State,
                   onDiscountTouchUp: (() -> Void)?,
                   onSwitchChange: ((Bool) -> Void)?,
                   onButtonTouchUp: (() -> Void)?) {
        self.onDiscountTouchUp = onDiscountTouchUp
        self.onSwitchChange = onSwitchChange
        self.onButtonTouchUp = onButtonTouchUp
        configureCellBasedOnState(state)
    }

    @IBAction private func toggleSwitchWasPressed(_ sender: Any) {
        onSwitchChange?(isOn)
    }
    @IBAction private func buttonTouchUpEvent(_ sender: Any) {
        onButtonTouchUp?()
    }

    func setPackageRates(_ rates: [String]) {
        packageRatesStackViews.forEach { stackView in
            mainStackView.removeArrangedSubview(stackView)
            stackView.removeFromSuperview()
        }
        if rates.isNotEmpty {
            packageRatesStackViews = rates.enumerated().map { (index, rateText) in
                let titleLabel = UILabel()
                titleLabel.applyBodyStyle()
                titleLabel.text = String(format: Localization.packageNumber, index + 1)
                titleLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)

                let descriptionLabel = UILabel()
                descriptionLabel.applyBodyStyle()
                descriptionLabel.textAlignment = .right // swiftlint:disable:this inverse_text_alignment
                descriptionLabel.text = rateText
                descriptionLabel.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal)

                let stackView = UIStackView()
                stackView.axis = .horizontal
                stackView.spacing = 8.0
                stackView.addArrangedSubviews([titleLabel, descriptionLabel])
                return stackView
            }
            packageRatesStackViews.enumerated().forEach { (index, stackView) in
                mainStackView.insertArrangedSubview(stackView, at: index)
            }
        }
        updateSubtotalLabels()
    }

    func setSubtotal(_ total: String) {
        subtotalBody.text = total
    }

    func setDiscount(_ discount: String?) {
        guard let discount = discount else {
            discountView.isHidden = true
            return
        }
        discountView.isHidden = false
        discountBody.text = discount
    }

    func setOrderTotal(_ total: String) {
        orderTotalBody.text = total
    }

    @objc private func discountViewTapped() {
        onDiscountTouchUp?()
    }
}

private extension ShippingLabelSummaryTableViewCell {
    func configureStyle() {
        applyDefaultBackgroundStyle()
        selectionStyle = .none
        discountImage.image = .infoOutlineImage
        separator.backgroundColor = .systemColor(.separator)
    }

    func configureLabels() {
        subtotalTitle.text = Localization.subtotal
        subtotalTitle.numberOfLines = 0
        subtotalBody.numberOfLines = 0
        updateSubtotalLabels()
        discountTitle.applyBodyStyle()
        discountTitle.text = Localization.discount
        discountTitle.numberOfLines = 0
        discountBody.applyBodyStyle()
        discountBody.numberOfLines = 0
        orderTotalTitle.applyHeadlineStyle()
        orderTotalTitle.text = Localization.orderTotal
        orderTotalTitle.numberOfLines = 0
        orderTotalBody.applyHeadlineStyle()
        orderTotalBody.numberOfLines = 0
        orderCompleteTitle.applySubheadlineStyle()
        orderCompleteTitle.text = Localization.orderComplete
        orderCompleteTitle.numberOfLines = 0
    }

    func updateSubtotalLabels() {
        if packageRatesStackViews.isEmpty {
            subtotalTitle.applyBodyStyle()
            subtotalBody.applyBodyStyle()
        } else {
            subtotalTitle.applyHeadlineStyle()
            subtotalBody.applyHeadlineStyle()
        }
    }

    func configureSwitch() {
        orderCompleteSwitch.onTintColor = .primary
    }

    func configureButton() {
        button.applyPrimaryButtonStyle()
        button.setTitle(Localization.button, for: .normal)
    }

    func configureCellBasedOnState(_ state: ShippingLabelFormStepTableViewCell.State) {
        switch state {
        case .disabled:
            button.isEnabled = false
        case .enabled:
            button.isEnabled = true
        case .continue:
            button.isEnabled = false
        }
    }
}

private extension ShippingLabelSummaryTableViewCell {
    enum Localization {
        static let subtotal = NSLocalizedString("Subtotal", comment: "Create Shipping Label form -> Subtotal label")
        static let discount = NSLocalizedString("WooCommerce Discount", comment: "Create Shipping Label form -> WooCommerce Discount label")
        static let orderTotal = NSLocalizedString("Order Total", comment: "Create Shipping Label form -> Order Total label")
        static let orderComplete = NSLocalizedString("Mark this order as complete and notify the customer",
                                                     comment: "Create Shipping Label form -> Mark order as complete label")
        static let button = NSLocalizedString("Purchase Label", comment: "Create Shipping Label form -> Purchase Label button")
        static let packageNumber = NSLocalizedString("Package %1$d", comment: "Create Shipping Label form -> Package number")
    }
}
