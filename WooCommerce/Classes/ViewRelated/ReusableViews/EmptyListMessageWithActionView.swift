import UIKit

final class EmptyListMessageWithActionView: UIView {
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var actionButton: BordersView!
    @IBOutlet private weak var actionButtonLabel: UILabel!

    var messageText: String? {
        get {
            return messageLabel.text
        }
        set {
            messageLabel.text = newValue
        }
    }

    var actionText: String? {
        get {
            return actionButtonLabel.text
        }
        set {
            actionButtonLabel.text = newValue
            configureActionButtonForVoiceOver()
        }
    }

    var onAction: (()-> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        applyBackgroundStyle()
        applyMessageLabelStyle()
        applyActionButtonStyle()
        applyActionLabelStyle()

        configureActionButtonGesture()
    }

    // MARK: - Public Methods

    /// Displays the receiver in a given superview. The Overlay will be attached to all edges.
    ///
    func attach(to superview: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(self)
        superview.pinSubviewToAllEdges(self)
    }
}


// MARK: - Styles
//
private extension EmptyListMessageWithActionView {
    func applyBackgroundStyle() {
        backgroundColor = .listBackground
    }

    func applyMessageLabelStyle() {
        messageLabel.textAlignment = .center
        messageLabel.applyEmptyStateTitleStyle()
    }

    func applyActionButtonStyle() {
        actionButton.backgroundColor = .listForeground
        actionButton.topVisible = true
        actionButton.bottomVisible = true
    }

    func applyActionLabelStyle() {
        actionButtonLabel.applyBodyStyle()
    }

    func configureActionButtonGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped))
        actionButton.addGestureRecognizer(gesture)
    }
}


// MARK: - Button action
//
private extension EmptyListMessageWithActionView {
    @objc func buttonTapped() {
        onAction?()
    }
}


// MARK: - Accessibility
//
private extension EmptyListMessageWithActionView {
    func configureActionButtonForVoiceOver() {
        actionButton.isAccessibilityElement = true
        actionButton.accessibilityLabel = actionButtonLabel.text
        actionButton.accessibilityTraits = .button
    }
}


// MARK: - Unit tests
//
extension EmptyListMessageWithActionView {
    func getMessageLabel() -> UILabel {
        return messageLabel
    }

    func getButton() -> BordersView {
        return actionButton
    }

    func getButtonLabel() -> UILabel {
        return actionButtonLabel
    }
}
