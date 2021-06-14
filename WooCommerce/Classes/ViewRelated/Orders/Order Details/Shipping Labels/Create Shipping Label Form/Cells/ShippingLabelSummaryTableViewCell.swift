import UIKit

final class ShippingLabelSummaryTableViewCell: UITableViewCell {

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
    }

    func configure(onSwitchChange: ((Bool) -> Void)?,
                   onButtonTouchUp: (() -> Void)?) {
        self.onSwitchChange = onSwitchChange
        self.onButtonTouchUp = onButtonTouchUp
    }

    @IBAction func toggleSwitchWasPressed(_ sender: Any) {
        onSwitchChange?(isOn)
    }
}

private extension ShippingLabelSummaryTableViewCell {
    func configureStyle() {
        applyDefaultBackgroundStyle()
        selectionStyle = .none
    }

    func configureLabels() {
        subtotalTitle.applyBodyStyle()
        subtotalTitle.text = Localization.subtotal
        subtotalBody.applyBodyStyle()
        discountTitle.applyBodyStyle()
        discountTitle.text = Localization.discount
        discountBody.applyBodyStyle()
        orderTotalTitle.applyTitleStyle()
        orderTotalTitle.text = Localization.orderTotal
        orderTotalBody.applyTitleStyle()
        orderCompleteTitle.applyBodyStyle()
        orderCompleteTitle.numberOfLines = 0
        orderCompleteTitle.text = Localization.orderComplete
    }

    func configureSwitch() {
        orderCompleteSwitch.onTintColor = .primary
    }

    func configureButton() {
        button.applyPrimaryButtonStyle()
    }
}

private extension ShippingLabelSummaryTableViewCell {
    enum Localization {
        static let subtotal = NSLocalizedString("Subtotal", comment: "Create Shipping Label form -> Subtotal label")
        static let discount = NSLocalizedString("WooCommerce Discount", comment: "Create Shipping Label form -> WooCommerce Discount label")
        static let orderTotal = NSLocalizedString("Order Total", comment: "Create Shipping Label form -> Order Total label")
        static let orderComplete = NSLocalizedString("Mark this order as complete and notify the customer",
                                                     comment: "Create Shipping Label form -> Mark order as complete label")
    }
}
