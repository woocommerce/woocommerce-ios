
import UIKit

/// Shows a view with a message and a standard empty search results image.
///
/// This is generally used with `SearchUICommand`.
///
final class EmptySearchResultsViewController: UIViewController, KeyboardFrameAdjustmentProvider {
    @IBOutlet private var messageLabel: UILabel! {
        didSet {
            // Remove dummy text in Interface Builder
            messageLabel.text = nil
        }
    }
    @IBOutlet private var imageView: UIImageView!

    /// The vertical center-y constraint of the StackView containing the image and text
    @IBOutlet private var stackViewCenterYConstraint: NSLayoutConstraint!

    private lazy var keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] in
        self?.verticallyAlignStackViewUsing(keyboardHeight: $0.height)
    })

    /// The font used by the message's `UILabel`.
    ///
    /// This is exposed so that consumers can build `NSAttributedString` instances using the same
    /// font. The `NSAttributedString` instance can then be used in `configure(message:`).
    ///
    var messageFont: UIFont {
        messageLabel.font
    }

    /// Required implementation by `KeyboardFrameAdjustmentProvider`.
    var additionalKeyboardFrameHeight: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        messageLabel.applyBodyStyle()

        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateImageVisibilityUsing(traits: traitCollection)
    }

    /// Change the message being displayed.
    ///
    /// This is the only "configurable" point for consumers using this class.
    ///
    func configure(message: NSAttributedString?) {
        messageLabel.attributedText = message
    }

    /// Watch for device orientation changes and update the `imageView`'s visibility accordingly.
    ///
    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.updateImageVisibilityUsing(traits: newCollection)
        }, completion: nil)
    }

    /// Hide the `imageView` if there is not enough vertical space (e.g. iPhone landscape).
    ///
    private func updateImageVisibilityUsing(traits: UITraitCollection) {
        let shouldShowImageView = traits.verticalSizeClass != .compact
        imageView.isHidden = !shouldShowImageView
    }

    /// Update the `stackViewCenterYConstraint` so that the StackView is kept vertically centered.
    ///
    /// We update the constant so that the StackView, which contains the image and message, is
    /// still vertically centered on the available space even if the keyboard is covering some
    /// of the view.
    ///
    private func verticallyAlignStackViewUsing(keyboardHeight: CGFloat) {
        let constraintConstant: CGFloat = {
            // Reset the constraint if the keyboard is not shown.
            guard keyboardHeight > 0 else {
                return 0
            }

            // Adjust the keyboard height using any adjustment given by a parent ViewController
            // (e.g. SearchViewController).
            let keyboardHeight = keyboardHeight + additionalKeyboardFrameHeight

            // Because this is a single Center-Y constraint, we only need to deduct half of the
            // keyboard height. This is like deducting 50% of the height from the top and the bottom.
            let heightToDeduct = keyboardHeight * 0.5

            return 0 - heightToDeduct
        }()

        stackViewCenterYConstraint.constant = constraintConstant
    }
}
