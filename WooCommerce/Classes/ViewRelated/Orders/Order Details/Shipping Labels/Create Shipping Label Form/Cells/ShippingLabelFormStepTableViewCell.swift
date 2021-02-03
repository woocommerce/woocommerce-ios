import UIKit


final class ShippingLabelFormStepTableViewCell: UITableViewCell {

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var body: UILabel!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var separator: UIImageView!
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
        self.icon.image = icon
        self.title.text = title
        self.body.text = body
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
        icon.tintColor = .neutral(.shade100)
        selectionStyle = .none
        separator.backgroundColor = .systemColor(.separator)
    }

    func configureLabels() {
        title.applyBodyStyle()
        body.applySubheadlineStyle()
        body.numberOfLines = 0
    }

    func configureButton() {
        button.applyPrimaryButtonStyle()
    }

    func configureCellBasedOnState(_ state: State) {
        switch state {
        case .disabled:
            icon.alpha = 0.3
            title.alpha = 0.3
            body.alpha = 0.3
            button.isHidden = true
            separatorLeadingConstraint.constant = Constants.separatorDefaultMargin
            accessoryType = .none
        case .enabled:
            icon.alpha = 0.6
            title.alpha = 1.0
            body.alpha = 0.6
            button.isHidden = true
            separatorLeadingConstraint.constant = Constants.separatorDefaultMargin
            accessoryType = .disclosureIndicator
        case .continue:
            icon.alpha = 1.0
            title.alpha = 1.0
            body.alpha = 0.6
            button.isHidden = false
            separatorLeadingConstraint.constant = Constants.separatorCustomMargin
            accessoryType = .none
        }
    }
}

private extension ShippingLabelFormStepTableViewCell {
    enum Constants {
        static let separatorCustomMargin: CGFloat = 0.0
        static let separatorDefaultMargin: CGFloat = 56.0
    }
}
