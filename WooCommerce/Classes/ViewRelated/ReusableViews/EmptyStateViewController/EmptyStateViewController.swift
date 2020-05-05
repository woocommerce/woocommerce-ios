
import UIKit

/// A configurable view to display an "empty state".
///
/// This can show (from top to bottom):
///
/// - A message
/// - An image
/// - A label suitable for a longer message
/// - An action button
///
/// These elements are hidden by default and can be configured and shown using
/// the `configure` method.
///
final class EmptyStateViewController: UIViewController, KeyboardFrameAdjustmentProvider {

    /// The submitted argument when configuring the `actionButton`.
    ///
    struct ActionButtonConfig {
        let title: String
        let onTap: () -> ()
    }

    /// The main message shown at the top.
    ///
    @IBOutlet private var messageLabel: UILabel! {
        didSet {
            // Remove dummy text in Interface Builder
            messageLabel.text = nil
            messageLabel.isHidden = true
        }
    }

    /// An image shown below the message.
    ///
    @IBOutlet private var imageView: UIImageView! {
        didSet {
            imageView.image = nil
            imageView.isHidden = true
        }
    }

    /// Additional text shown below the image.
    ///
    @IBOutlet private var detailsLabel: UILabel! {
        didSet {
            detailsLabel.text = nil
            detailsLabel.isHidden = true
        }
    }

    /// The button shown below the detail text.
    ///
    @IBOutlet private var actionButton: UIButton! {
        didSet {
            actionButton.setTitle(nil, for: .normal)
            actionButton.isHidden = true
        }
    }

    /// The scrollable view containing all the content (labels, image, etc).
    ///
    @IBOutlet private var scrollView: UIScrollView!

    /// The height adjustment constraint for the content view.
    ///
    /// The contentView's height = superview's height + offset/adjustment. Only the
    /// offset/adjustment is changed. See `verticallyAlignStackViewUsing`.
    ///
    /// This constraint has low priority to allow the content view to increase the height if the
    /// text (message) is too big.
    ///
    @IBOutlet private var contentViewHeightAdjustmentFromSuperviewConstraint: NSLayoutConstraint!

    /// The last `ActionButtonConfig` passed during `configure()`
    ///
    private var lastActionButtonConfig: ActionButtonConfig?

    /// The handler to execute when the button is tapped.
    ///
    /// This is normally set up in `configure()`.
    ///
    private var lastActionButtonTapHandler: (() -> ())?

    private lazy var keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] frame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: frame)
        self?.verticallyAlignStackViewUsing(keyboardHeight: frame.height)
    })

    /// The font used by the message's `UILabel`.
    ///
    /// This is exposed so that consumers can build `NSAttributedString` instances using the same
    /// font. The `NSAttributedString` instance can then be used in `configure(message:`).
    ///
    /// This must match the `applyBodyStyle()` call in `viewDidLoad`.
    ///
    static let messageFont: UIFont = .body

    /// Required implementation by `KeyboardFrameAdjustmentProvider`.
    var additionalKeyboardFrameHeight: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground

        messageLabel.applyBodyStyle()
        detailsLabel.applySecondaryBodyStyle()
        actionButton.applyPrimaryButtonStyle()

        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateImageVisibilityUsing(traits: traitCollection)
    }

    /// Configure the elements to be displayed.
    ///
    func configure(_ config: Config) {
        messageLabel.attributedText = config.message
        messageLabel.isHidden = false

        imageView.image = config.image
        imageView.isHidden = false

        detailsLabel.text = config.details
        detailsLabel.isHidden = config.details == nil

        actionButton.setTitle(config.actionButtonTitle, for: .normal)
        actionButton.isHidden = config.actionButtonTitle == nil

        lastActionButtonTapHandler = nil

        if case let Config.withLink(_, _, _, _, linkURL) = config {
            lastActionButtonTapHandler = {
                #warning("Show the linkURL")
            }
        }
    }

    /// Change the elements being displayed.
    ///
    /// This is the only "configurable" point for consumers using this class.
    ///
    func configure(message: NSAttributedString? = nil,
                   image: UIImage? = nil,
                   details: String? = nil,
                   actionButton actionButtonConfig: ActionButtonConfig? = nil) {
        messageLabel.attributedText = message
        messageLabel.isHidden = message == nil

        imageView.image = image
        imageView.isHidden = image == nil

        detailsLabel.text = details
        detailsLabel.isHidden = details == nil

        lastActionButtonConfig = actionButtonConfig
        actionButton.setTitle(actionButtonConfig?.title, for: .normal)
        actionButton.isHidden = actionButtonConfig == nil
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
        let shouldShowImageView = traits.verticalSizeClass != .compact &&
            imageView.image != nil
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

        contentViewHeightAdjustmentFromSuperviewConstraint.constant = constraintConstant
    }

    /// OnTouchUpInside handler for the `actionButton`.
    @IBAction private func actionButtonTapped(_ sender: Any) {
        lastActionButtonConfig?.onTap()
    }
}

// MARK: - KeyboardScrollable

extension EmptyStateViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        scrollView
    }
}

// MARK: - Config

extension EmptyStateViewController {
    /// The configuration for this Empty State View
    enum Config {
        /// The font used by the message's `UILabel`.
        ///
        /// This is exposed so that consumers can build `NSAttributedString` instances using the same
        /// font. The `NSAttributedString` instance can then be used in `configure(message:`).
        ///
        /// This must match the `applyBodyStyle()` call in `viewDidLoad`.
        ///
        static let messageFont: UIFont = .body

        /// Show a message and image only.
        ///
        case simple(message: NSAttributedString, image: UIImage)
        /// Show all the elements and a button which navigates to a URL when tapped.
        ///
        case withLink(message: NSAttributedString, image: UIImage, details: String, linkTitle: String, linkURL: URL)

        fileprivate var message: NSAttributedString {
            switch self {
            case .simple(let message, _),
                 .withLink(let message, _, _, _, _):
                return message
            }
        }

        fileprivate var image: UIImage {
            switch self {
            case .simple(_, let image),
                 .withLink(_, let image, _, _, _):
                return image
            }
        }

        fileprivate var details: String? {
            switch self {
            case .simple:
                return nil
            case .withLink(_, _, let detail, _, _):
                return detail
            }
        }

        fileprivate var actionButtonTitle: String? {
            switch self {
            case .simple:
                return nil
            case .withLink(_, _, _, let linkTitle, _):
                return linkTitle
            }
        }
    }
}

