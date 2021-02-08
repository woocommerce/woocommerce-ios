import UIKit


final class ShippingLabelFormStepTableViewCell: UITableViewCell {

    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var disclosureIndicatorView: UIView!
    @IBOutlet private weak var chevronView: UIImageView!
    @IBOutlet private weak var separator: UIView!
    @IBOutlet private weak var separatorLeadingConstraint: NSLayoutConstraint!

    private var onButtonTouchUp: (() -> Void)?

    enum State {
        /// The row is greyed out, and the button is hidden
        case disabled

        /// The row is enabled and tappable, and the button is hidden
        case enabled

        /// The row is enabled, and the button is visible
        case `continue`
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureStyle()
        configureLabels()
        configureButton()
    }

    func configure(state: State,
                   icon: UIImage,
                   title: String?,
                   body: String?,
                   buttonTitle: String?,
                   onButtonTouchUp: (() -> Void)? = nil) {
        iconView.image = icon
        titleLabel.text = title
        bodyLabel.text = body
        button.setTitle(buttonTitle, for: .normal)
        self.onButtonTouchUp = onButtonTouchUp
        configureCellBasedOnState(state)
    }
}

private extension ShippingLabelFormStepTableViewCell {
    @IBAction func buttonTouchUpEvent(_ sender: Any) {
        onButtonTouchUp?()
    }
}

private extension ShippingLabelFormStepTableViewCell {
    func configureStyle() {
        applyDefaultBackgroundStyle()
        iconView.tintColor = .neutral(.shade100)
        selectionStyle = .none
        chevronView.image = .chevronImage
        chevronView.tintColor = .neutral(.shade100)
        chevronView.alpha = 0.3
        separator.backgroundColor = .systemColor(.separator)
    }

    func configureLabels() {
        titleLabel.applyBodyStyle()
        bodyLabel.applySubheadlineStyle()
        bodyLabel.numberOfLines = 0
    }

    func configureButton() {
        button.applyPrimaryButtonStyle()
    }

    func configureCellBasedOnState(_ state: State) {
        switch state {
        case .disabled:
            iconView.alpha = 0.3
            titleLabel.alpha = 0.3
            bodyLabel.alpha = 0.3
            button.isHidden = true
            disclosureIndicatorView.isHidden = true
            separatorLeadingConstraint.constant = Constants.separatorDefaultMargin
        case .enabled:
            iconView.alpha = 0.6
            titleLabel.alpha = 1.0
            bodyLabel.alpha = 0.6
            button.isHidden = true
            disclosureIndicatorView.isHidden = false
            separatorLeadingConstraint.constant = Constants.separatorDefaultMargin
        case .continue:
            iconView.alpha = 1.0
            titleLabel.alpha = 1.0
            bodyLabel.alpha = 0.6
            button.isHidden = false
            disclosureIndicatorView.isHidden = true
            separatorLeadingConstraint.constant = Constants.separatorCustomMargin
        }
    }
}

private extension ShippingLabelFormStepTableViewCell {
    enum Constants {
        static let separatorCustomMargin: CGFloat = 0.0
        static let separatorDefaultMargin: CGFloat = 56.0
    }
}
