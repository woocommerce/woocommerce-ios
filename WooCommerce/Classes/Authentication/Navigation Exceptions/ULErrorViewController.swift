import Combine
import UIKit
import WordPressAuthenticator
import SafariServices


/// UI presenting errors in the Unified Login flow.
/// This view controller can either be presented from within WooCommerce
/// or be injected into WordPressAuthenticator.
final class ULErrorViewController: UIViewController {
    /// The view model providing configuration for this view controller
    /// and support for user actions
    private let viewModel: ULErrorViewModel

    /// Contains a vertical stack of the image, error message, and extra info button by default.
    @IBOutlet private weak var containerStackViewWithSeparatorLines: UIStackView!
    @IBOutlet private weak var extraButtonsStackView: UIStackView!
    @IBOutlet private weak var extraInfoButton: UIButton!
    @IBOutlet private weak var topSeparatorLine: UIView!
    @IBOutlet private weak var bottomSeparatorLine: UIView!

    @IBOutlet private weak var primaryButton: ButtonActivityIndicator!
    @IBOutlet private weak var secondaryButton: UIButton!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var errorMessage: UILabel!
    @IBOutlet private weak var termsLabel: UITextView!

    @IBOutlet private weak var siteAddressContainerView: UIView!
    @IBOutlet private weak var siteAddressImageView: UIImageView!
    @IBOutlet private weak var siteAddressLabel: UILabel!

    /// Constraints on the view containing the action buttons
    /// and the stack view containing the image and error text
    /// Used to adjust the button width in unified views provided by WPAuthenticator
    @IBOutlet private weak var buttonViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var buttonViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackViewTrailingConstraint: NSLayoutConstraint!

    private var primaryButtonSubscription: AnyCancellable?
    private var siteFaviconSubscription: AnyCancellable?

    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.isPad() ? .all : .portrait
    }

    init(viewModel: ULErrorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTitle()
        configureRightBarButtonItem()
        configureImageView()
        configureErrorMessage()
        configureExtraInfoButton()
        configureAuxiliaryView()
        configureSeparatorLines()
        configureSiteAddressView()

        configurePrimaryButton()
        configureSecondaryButton()
        configureTermsLabel()

        configureButtonLabels()

        setUnifiedMargins(forWidth: view.frame.width)

        viewModel.viewDidLoad(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setUnifiedMargins(forWidth: view.frame.width)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setUnifiedMargins(forWidth: size.width)
    }
}


// MARK: - View configuration
private extension ULErrorViewController {
    func configureTitle() {
        title = viewModel.title
    }

    func configureRightBarButtonItem() {
        guard let rightBarButtonTitle = viewModel.rightBarButtonItemTitle else {
            return
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapRightBarButtonItem))
    }

    func configureImageView() {
        imageView.image = viewModel.image
    }

    func configureErrorMessage() {
        errorMessage.applyBodyStyle()
        errorMessage.attributedText = viewModel.text
    }

    func configureExtraInfoButton() {
        guard viewModel.isAuxiliaryButtonHidden == false else {
            extraInfoButton.isHidden = true

            // Hide the whole stackview to avoid showing separator lines with no views inside.
            containerStackViewWithSeparatorLines.isHidden = viewModel.auxiliaryView == nil

            return
        }

        extraInfoButton.applyLinkButtonStyle()
        extraInfoButton.contentEdgeInsets = Constants.extraInfoCustomInsets
        extraInfoButton.setTitle(viewModel.auxiliaryButtonTitle, for: .normal)
        extraInfoButton.titleLabel?.textAlignment = .center
        extraInfoButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapAuxiliaryButton()
        }
    }

    func configureTermsLabel() {
        let linkAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.accent,
            NSAttributedString.Key.underlineColor: UIColor.accent,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        termsLabel.linkTextAttributes = linkAttributes
        termsLabel.isSelectable = true
        termsLabel.isHidden = viewModel.termsLabelText == nil
        if let text = viewModel.termsLabelText {
            termsLabel.attributedText = text
        }
    }

    func configureAuxiliaryView() {
        guard let auxiliaryView = viewModel.auxiliaryView else {
            return
        }
        extraButtonsStackView.addArrangedSubview(auxiliaryView)
    }

    func configureSeparatorLines() {
        topSeparatorLine.backgroundColor = .systemColor(.separator)
        bottomSeparatorLine.backgroundColor = .systemColor(.separator)
    }

    func configureSiteAddressView() {
        guard !viewModel.isSiteAddressViewHidden else {
            siteAddressContainerView.isHidden = true
            return
        }
        siteAddressContainerView.isHidden = false
        siteAddressContainerView.layer.borderWidth = 0.5
        siteAddressContainerView.layer.borderColor = UIColor.border.cgColor
        siteAddressContainerView.layer.cornerRadius = 4
        siteAddressContainerView.clipsToBounds = true

        siteAddressLabel.applyBodyStyle()
        siteAddressLabel.numberOfLines = 0
        siteAddressLabel.text = viewModel.siteURL.trimHTTPScheme()

        siteAddressImageView.tintColor = .text
        siteFaviconSubscription = viewModel.siteFavicon
            .sink { [weak self] icon in
                self?.siteAddressImageView.image = icon
            }
    }

    func configurePrimaryButton() {
        primaryButton.applyPrimaryButtonStyle()
        primaryButton.isHidden = viewModel.isPrimaryButtonHidden
        primaryButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        primaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapPrimaryButton()
        }

        // We need to wait until view did appear to make sure the indicator stays at the correct position
        primaryButtonSubscription = viewModel.isPrimaryButtonLoading.combineLatest(viewDidAppearSubject.prefix(1))
            .sink { [weak self] (isLoading, _) in
                guard let self = self else { return }
                self.primaryButton.isEnabled = !isLoading
                if isLoading {
                    self.primaryButton.showActivityIndicator()
                } else {
                    self.primaryButton.hideActivityIndicator()
                }
            }
    }

    func configureSecondaryButton() {
        secondaryButton.applySecondaryButtonStyle()
        secondaryButton.isHidden = viewModel.isSecondaryButtonHidden
        secondaryButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
        secondaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapSecondaryButton()
        }
    }

    func configureButtonLabels() {
        let buttons = [extraInfoButton, primaryButton, secondaryButton]
        for button in buttons {
            button?.titleLabel?.numberOfLines = 0
            button?.titleLabel?.lineBreakMode = .byWordWrapping
        }
    }


    /// This logic is lifted from WPAuthenticator's LoginPrologueViewController
    /// This View Controller will be provided to WPAuthenticator. WPAuthenticator
    /// will insert it into its own navigation stack, where it is applying a similar logic
    func setUnifiedMargins(forWidth viewWidth: CGFloat) {
        guard traitCollection.horizontalSizeClass == .regular &&
                traitCollection.verticalSizeClass == .regular else {
            buttonViewLeadingConstraint?.constant = ButtonViewMarginMultipliers.defaultButtonViewMargin
            buttonViewTrailingConstraint?.constant = ButtonViewMarginMultipliers.defaultButtonViewMargin
            return
        }

        let marginMultiplier = UIDevice.current.orientation.isLandscape ?
            ButtonViewMarginMultipliers.ipadLandscape :
            ButtonViewMarginMultipliers.ipadPortrait

        let margin = viewWidth * marginMultiplier

        buttonViewLeadingConstraint?.constant = margin
        buttonViewTrailingConstraint?.constant = margin

        stackViewLeadingConstraint?.constant = margin
        stackViewTrailingConstraint?.constant = margin
    }

    private enum ButtonViewMarginMultipliers {
        static let ipadPortrait: CGFloat = 0.1667
        static let ipadLandscape: CGFloat = 0.25
        static let defaultButtonViewMargin: CGFloat = 0.0
    }
}


// MARK: - Actions
private extension ULErrorViewController {
    func didTapAuxiliaryButton() {
        viewModel.didTapAuxiliaryButton(in: self)
    }

    func didTapPrimaryButton() {
        viewModel.didTapPrimaryButton(in: self)
    }

    func didTapSecondaryButton() {
        viewModel.didTapSecondaryButton(in: self)
    }

    @objc func didTapRightBarButtonItem() {
        viewModel.didTapRightBarButtonItem(in: self)
    }
}


// MARK: - Constants
private extension ULErrorViewController {
    enum Constants {
        static let extraInfoCustomInsets = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
    }
}

// MARK: - Tests
extension ULErrorViewController {
    func getImageView() -> UIImageView {
        return imageView
    }

    func getLabel() -> UILabel {
        return errorMessage
    }

    func getAuxiliaryButton() -> UIButton {
        return extraInfoButton
    }

    func primaryActionButton() -> UIButton {
        return primaryButton
    }

    func secondaryActionButton() -> UIButton {
        return secondaryButton
    }

    func getTermsLabel() -> UITextView {
        return termsLabel
    }
}
