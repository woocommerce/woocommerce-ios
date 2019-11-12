import Foundation
import UIKit


/// OverlayMessageView: Displays an `Image + Text + Action` in a given superview.
///
class OverlayMessageView: UIView {

    /// Overlay's ImageView.
    ///
    @IBOutlet private var imageView: UIImageView!

    /// Overlay's Message Label.
    ///
    @IBOutlet private var messageLabel: UILabel!

    /// Overlay's Action Button.
    ///
    @IBOutlet private var actionButton: UIButton!

    /// Overlay's Top Image.
    ///
    var messageImage: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }

    /// Message to be displayed below the Image.
    ///
    var messageText: String? {
        get {
            return messageLabel.text
        }
        set {
            messageLabel.text = newValue
        }
    }

    /// Action Button's visibility.
    ///
    var actionVisible: Bool {
        get {
            return actionButton.isHidden == false
        }
        set {
            actionButton.isHidden = !newValue
        }
    }

    /// Action Button's Text.
    ///
    var actionText: String? {
        get {
            return actionButton.titleLabel?.text
        }
        set {
            actionButton.setTitle(newValue, for: .normal)
        }
    }

    /// Action button view (get only) — needed typically for the sharing popover on iPads.
    ///
    var actionButtonView: UIView {
        return actionButton
    }


    /// Closure to be executed whenever the Action Button is pressed.
    ///
    var onAction: (() -> Void)?



    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .listBackground
        messageLabel.applyBodyStyle()
        actionButton.applySecondaryButtonStyle()
    }


    // MARK: - Public Methods

    /// Displays the receiver in a given superview. The Overlay will be attached to all edges.
    ///
    func attach(to superview: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(self)
        superview.pinSubviewToAllEdges(self)
    }


    // MARK: - IBActions

    @IBAction func buttonWasPressed() {
        onAction?()
    }
}
