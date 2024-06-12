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

    /// The main message shown at the top.
    ///
    @IBOutlet private var messageLabel: UILabel! {
        didSet {
            // Remove dummy text in Interface Builder
            messageLabel.text = nil
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

    /// The scrollable view which contains the `contentView`.
    ///
    @IBOutlet private var scrollView: UIScrollView!
    /// The child of the scrollView which contains the `stackView`.
    ///
    @IBOutlet private var contentView: UIView!
    /// The child of the contentView containing all the content (labels, image, etc).
    ///
    @IBOutlet private weak var stackView: UIStackView!


    /// The height adjustment constraint for the content view.
    ///
    /// The contentView's height = superview's height + offset/adjustment. Only the
    /// offset/adjustment is changed. See `verticallyAlignStackViewUsing`.
    ///
    /// This constraint has low priority to allow the content view to increase the height if the
    /// text (message) is too big.
    ///
    @IBOutlet private var contentViewHeightAdjustmentFromSuperviewConstraint: NSLayoutConstraint!

    /// The configured style for this view.
    ///
    private let style: Style

    /// Initial configuration.
    /// Useful when rendering this view controller using the UIKit presentation APIs.
    ///
    private var configuration: Config?

    /// The handler to execute when the button is tapped.
    ///
    /// This is normally set up in `configure()`.
    ///
    private var lastActionButtonTapHandler: (() -> ())?

    /// The handler to execute when the view is pulled to refresh.
    ///
    private var pullToRefreshHandler: ((UIRefreshControl) -> ())?

    private lazy var keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] frame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: frame)
        self?.verticallyAlignStackViewUsing(keyboardHeight: frame.height)
    })

    /// Required implementation by `KeyboardFrameAdjustmentProvider`.
    var additionalKeyboardFrameHeight: CGFloat = 0

    /// Used to present the Contact Support dialog if the `Config` is `.withSupportRequest`.
    private let zendeskManager: ZendeskManagerProtocol

    /// Used to pin the stackView to the center of the visible area in the contact view,
    /// taking account of the banner view when it's shown.
    private lazy var visiblyCenteredLayoutGuide: UILayoutGuide = {
        let centerGuide = UILayoutGuide()
        contentView.addLayoutGuide(centerGuide)
        let topConstraint = centerGuide.topAnchor.constraint(equalTo: contentView.topAnchor)
        topConstraint.priority = UILayoutPriority(250)
        NSLayoutConstraint.activate([
            topConstraint,
            centerGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            centerGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            centerGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)])
        return centerGuide
    }()

    /// Top banner that shows an error if there is a problem loading data
    ///
    private var topBannerView: TopBannerView?

    convenience init(style: Style = .basic, configuration: Config? = nil, zendeskManager: ZendeskManagerProtocol? = nil) {
        if let zendeskManager = zendeskManager {
            self.init(style: style, configuration: configuration, zendesk: zendeskManager)
        } else {
            #if !targetEnvironment(macCatalyst)
            self.init(style: style, configuration: configuration, zendesk: ZendeskProvider.shared)
            #else
            self.init(style: style, configuration: configuration, zendesk: NoZendeskManager())
            #endif
        }
    }

    init(style: Style, configuration: Config?, zendesk: ZendeskManagerProtocol) {
        self.style = style
        self.configuration = configuration
        self.zendeskManager = zendesk
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = style.backgroundColor
        contentView.backgroundColor = style.backgroundColor
        NSLayoutConstraint.activate([stackView.centerYAnchor.constraint(equalTo: visiblyCenteredLayoutGuide.centerYAnchor)])

        messageLabel.applySecondaryTitleStyle()
        detailsLabel.applySecondaryBodyStyle()

        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)

        if let configuration = configuration {
            configure(configuration)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateImageVisibilityUsing(traits: traitCollection)
    }

    /// Configure the elements to be displayed.
    ///
    func configure(_ config: Config) {
        _ = view // trigger loading view before configuring contents
        configuration = config
        messageLabel.attributedText = config.message

        imageView.image = config.image
        updateImageVisibilityUsing(traits: traitCollection)

        detailsLabel.text = config.details
        detailsLabel.isHidden = config.details == nil

        configureActionButton(config)

        lastActionButtonTapHandler = {
            switch config {
            case .withLink(_, _, _, _, let linkURL, _):
                return { [weak self] in
                    if let self = self {
                        WebviewHelper.launch(linkURL, with: self)
                    }
                }
            case .withButton(_, _, _, _, let tapClosure, _):
                return { [weak self] in
                    if let self = self {
                        tapClosure(self.actionButton)
                    }
                }
            case .withSupportRequest:
                return { [weak self] in
                    if let self = self {
                        let supportForm = SupportFormHostingController(viewModel: .init())
                        supportForm.show(from: self)
                    }
                }
            default:
                return nil
            }
        }()

        configurePullToRefresh(config)
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
            imageView?.image != nil
        imageView?.isHidden = !shouldShowImageView
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
        lastActionButtonTapHandler?()
    }

    /// Display the error banner at the top of the view
    ///
    func showTopBannerView(for error: Error) {
        topBannerView = ErrorTopBannerFactory.createTopBanner(for: error,
                                                              expandedStateChangeHandler: {},
                                                              onTroubleshootButtonPressed: { [weak self] in
            guard let self else { return }

            WebviewHelper.launch(ErrorTopBannerFactory.troubleshootUrl(for: error), with: self)
        },
                                                              onContactSupportButtonPressed: { [weak self] in
            guard let self else { return }

            let supportForm = SupportFormHostingController(viewModel: .init())
            supportForm.show(from: self)
        })

        guard let topBannerView else { return }
        contentView.insertSubview(topBannerView, at: 0)
        NSLayoutConstraint.activate([
            topBannerView.leadingAnchor.constraint(equalTo: contentView.safeLeadingAnchor),
            topBannerView.trailingAnchor.constraint(equalTo: contentView.safeTrailingAnchor),
            topBannerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topBannerView.bottomAnchor.constraint(lessThanOrEqualTo: stackView.topAnchor, constant: -16),
            visiblyCenteredLayoutGuide.topAnchor.constraint(equalTo: topBannerView.bottomAnchor)
        ])
    }

    /// Hide the error banner at the top of the view
    ///
    func hideTopBannerView() {
        topBannerView?.removeFromSuperview()
    }
}

// MARK: - Configuration

private extension EmptyStateViewController {
    @objc func onPullToRefresh(sender: UIRefreshControl) {
        pullToRefreshHandler?(sender)
    }

    /// Configures the `actionButton` based on the given `config`.
    func configureActionButton(_ config: Config) {
        switch config {
        case .simple:
            actionButton.isHidden = true
        case .simpleImageWithDescription:
            actionButton.isHidden = true
        case .withLink(_, _, _, let title, _, _), .withButton(_, _, _, let title, _, _):
            actionButton.isHidden = false
            actionButton.applyPrimaryButtonStyle()
            actionButton.setTitle(title, for: .normal)
        case .withSupportRequest(_, _, _, let buttonTitle, _):
            actionButton.isHidden = false
            actionButton.applyLinkButtonStyle()
            var configuration = UIButton.Configuration.filled()
            configuration.contentInsets = .init(.zero)
            actionButton.setTitle(buttonTitle, for: .normal)
        }
    }

    /// Configures pull to refresh based on the given `config`
    func configurePullToRefresh(_ config: Config) {
        pullToRefreshHandler = {
            switch config {
            case .simple(_, _, let pullToRefreshClosure):
                return pullToRefreshClosure
            case .simpleImageWithDescription(_, _, let pullToRefreshClosure):
                return pullToRefreshClosure
            case .withLink(_, _, _, _, _, let pullToRefreshClosure):
                return pullToRefreshClosure
            case .withButton(_, _, _, _, _, let pullToRefreshClosure):
                return pullToRefreshClosure
            case .withSupportRequest(_, _, _, _, let pullToRefreshClosure):
                return pullToRefreshClosure
            }
        }()

        guard pullToRefreshHandler != nil else {
            // Remove refresh control if config doesn't have action handler
            return scrollView.refreshControl = nil
        }

        // Create refresh control if needed
        if scrollView.refreshControl == nil {
            scrollView.refreshControl = UIRefreshControl()
        }
        scrollView.refreshControl?.addTarget(self, action: #selector(onPullToRefresh(sender:)), for: .valueChanged)
    }
}

// MARK: - KeyboardScrollable

extension EmptyStateViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        scrollView
    }
}

// MARK: - Styling and Configuration

extension EmptyStateViewController {
    /// The style applied.
    ///
    /// The style is currently just the background color. ¯\_(ツ)_/¯
    ///
    enum Style {
        /// Shows a light background.
        case basic
        /// Shows a gray background.
        case list

        fileprivate var backgroundColor: UIColor {
            switch self {
            case .basic:
                return .basicBackground
            case .list:
                return .listBackground
            }
        }
    }

    /// The configuration for this Empty State View
    ///
    /// The options like `simple`, `withLink`, etc define the standard behaviors or styles that
    /// we use throughout the app. Right now, the options are generally split by the behavior
    /// of the `actionButton`.
    ///
    /// There are probably better solutions than this but we should try to limit these to
    /// what the design standards tell us. I believe it's better to have simple options than
    /// having a high degree of customizability.
    ///
    enum Config {
        typealias PullToRequestActionHandler = ((UIRefreshControl) -> Void)
        /// Show a message and image only.
        ///
        case simple(message: NSAttributedString, image: UIImage, onPullToRefresh: PullToRequestActionHandler? = nil)

        /// Show an image and description only.
        ///
        case simpleImageWithDescription(image: UIImage,
                                       details: String,
                                       onPullToRefresh: PullToRequestActionHandler? = nil)

        /// Show all the elements and a prominent button which navigates to a URL when activated.
        ///
        /// - Parameters:
        ///     - linkTitle: The content shown on the `actionButton`.
        ///     - linkURL: The URL that will be navigated to when the `actionButton` is activated.
        ///
        case withLink(message: NSAttributedString,
                      image: UIImage,
                      details: String,
                      linkTitle: String,
                      linkURL: URL,
                      onPullToRefresh: PullToRequestActionHandler? = nil)

        /// Show all the elements and a prominent button which calls back the provided closure when tapped.
        ///
        /// - Parameters:
        ///     - buttonTitle: The content shown on the `actionButton`.
        ///     - onTap: Closure to be executed when the button is tapped.
        ///
        case withButton(message: NSAttributedString,
                        image: UIImage,
                        details: String,
                        buttonTitle: String,
                        onTap: (UIButton) -> Void,
                        onPullToRefresh: PullToRequestActionHandler? = nil)

        /// Shows all the elements and a text-style button which shows the Contact Us dialog when activated.
        ///
        /// - Parameter buttonTitle: The content shown on the button that displays the Contact Support dialog.
        ///
        case withSupportRequest(message: NSAttributedString,
                                image: UIImage,
                                details: String,
                                buttonTitle: String,
                                onPullToRefresh: PullToRequestActionHandler? = nil)

        /// The font used by the message's `UILabel`.
        ///
        /// This is exposed so that consumers can build `NSAttributedString` instances using the same
        /// font. The `NSAttributedString` instance can then be used in `configure(message:`).
        ///
        /// This must match the `messageLabel` style applied in `viewDidLoad`.
        ///
        static let messageFont: UIFont = .title2

        fileprivate var message: NSAttributedString {
            switch self {
            case .simpleImageWithDescription:
                // In order to avoid making changes across multiple uses of `message` by making this optional
                // we opted for simply returning an empty NSAttributedString, which isn't used.
                // Ref: https://github.com/woocommerce/woocommerce-ios/pull/12214/files#r1513826124
                return NSAttributedString(string: "")
            case .simple(let message, _, _),
                    .withLink(let message, _, _, _, _, _),
                    .withButton(let message, _, _, _, _, _),
                    .withSupportRequest(let message, _, _, _, _):
                return message
            }
        }

        fileprivate var image: UIImage {
            switch self {
            case .simple(_, let image, _),
                    .simpleImageWithDescription(let image, _, _),
                    .withLink(_, let image, _, _, _, _),
                    .withButton(_, let image, _, _, _, _),
                    .withSupportRequest(_, let image, _, _, _):
                return image
            }
        }

        fileprivate var details: String? {
            switch self {
            case .simple:
                return nil
            case .simpleImageWithDescription( _, let detail, _),
                    .withLink(_, _, let detail, _, _, _),
                    .withButton(_, _, let detail, _, _, _),
                    .withSupportRequest(_, _, let detail, _, _):
                return detail
            }
        }
    }
}
