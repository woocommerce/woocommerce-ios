import UIKit

final class ShippingLabelFormStepTableViewCell: UITableViewCell {

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var body: UILabel!
    @IBOutlet private weak var button: UIButton!

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
        icon.tintColor = .black
    }

    func configureLabels() {
        title.applyBodyStyle()
        body.applyCaption1Style()
        body.numberOfLines = 0
    }

    func configureButton() {
        button.applyPrimaryButtonStyle()
    }

    func configureCellBasedOnState(_ state: State) {
        switch state {
        case .disabled:
            icon.alpha = 0.3
            title.applyCaption1Style()
            title.alpha = 0.3
            body.alpha = 0.3
            button.isHidden = true
        case .enabled:
            icon.alpha = 0.6
            title.applyBodyStyle()
            title.alpha = 1.0
            body.alpha = 0.6
            button.isHidden = true
        case .continue:
            icon.alpha = 1.0
            title.applyBodyStyle()
            title.alpha = 1.0
            body.alpha = 0.6
            button.isHidden = false
        }
    }
}
