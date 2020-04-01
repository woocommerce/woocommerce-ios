
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
    @IBOutlet private var scrollView: UIScrollView!

    /// The height constraint for the content view.
    ///
    /// This constraint has low priority to allow the content view to increase the height if the
    /// text (message) is too big.
    ///
    @IBOutlet private var contentViewHeightConstraint: NSLayoutConstraint!

    private lazy var keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] frame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: frame)
        self?.verticallyAlignStackViewUsing(keyboardHeight: frame.height)
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

        view.backgroundColor = .basicBackground

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

    /// Update the `contentViewHeightConstraint` so that the StackView is kept vertically centered.
    ///
    /// This routine decreases the height constraint so that it will fit in the available space
    /// that's not covered by the keyboard. Note that if the space is too small, the other
    /// xib constraints defined in the layout will automatically increase the height instead.
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

            return 0 - keyboardHeight
        }()

        contentViewHeightConstraint.constant = constraintConstant
    }
}

// MARK: - KeyboardScrollable

extension EmptySearchResultsViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        scrollView
    }
}
