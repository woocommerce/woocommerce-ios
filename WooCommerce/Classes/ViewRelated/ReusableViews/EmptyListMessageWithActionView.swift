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

    var onAction: (() -> Void)?

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
extension EmptyListMessageWithActionView {
    fileprivate func applyBackgroundStyle() {
        backgroundColor = StyleManager.tableViewBackgroundColor
    }

    fileprivate func applyMessageLabelStyle() {
        messageLabel.textAlignment = .center
        messageLabel.applyEmptyStateTitleStyle()
    }

    fileprivate func applyActionButtonStyle() {
        actionButton.backgroundColor = .white
        actionButton.topVisible = true
        actionButton.bottomVisible = true
    }

    fileprivate func applyActionLabelStyle() {
        actionButtonLabel.applyBodyStyle()
    }

    fileprivate func configureActionButtonGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped))
        actionButton.addGestureRecognizer(gesture)
    }
}


// MARK: - Button action
//
extension EmptyListMessageWithActionView {
    @objc
    fileprivate func buttonTapped() {
        onAction?()
    }
}


// MARK: - Accessibility
//
extension EmptyListMessageWithActionView {
    fileprivate func configureActionButtonForVoiceOver() {
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
