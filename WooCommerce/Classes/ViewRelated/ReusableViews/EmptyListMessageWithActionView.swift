import UIKit

final class EmptyListMessageWithActionView: UIView {
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var actionButton: UIView!
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
        backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func applyMessageLabelStyle() {
        messageLabel.textAlignment = .center
        messageLabel.applyEmptyStateTitleStyle()
    }

    func applyActionButtonStyle() {
        actionButton.backgroundColor = .white
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
