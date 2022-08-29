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
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var primaryButton: NUXButton!
    @IBOutlet private weak var secondaryButton: UIButton!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var errorMessage: UILabel!
    @IBOutlet private weak var extraInfoButton: UIButton!

    /// Constraints on the view containing the action buttons
    /// and the stack view containing the image and error text
    /// Used to adjust the button width in unified views provided by WPAuthenticator
    @IBOutlet private weak var buttonViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var buttonViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stackViewTrailingConstraint: NSLayoutConstraint!

    private var primaryButtonSubscription: AnyCancellable?

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
        configureImageView()
        configureErrorMessage()
        configureExtraInfoButton()
        configureAuxiliaryView()

        configurePrimaryButton()
        configureSecondaryButton()

        configureButtonLabels()

        setUnifiedMargins(forWidth: view.frame.width)

        viewModel.viewDidLoad(self)
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

    func configureAuxiliaryView() {
        guard let auxiliaryView = viewModel.auxiliaryView else {
            return
        }
        contentStackView.addArrangedSubview(auxiliaryView)
    }

    func configurePrimaryButton() {
        primaryButton.isPrimary = true
        primaryButton.isHidden = viewModel.isPrimaryButtonHidden
        primaryButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        primaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapPrimaryButton()
        }
    
        primaryButtonSubscription = viewModel.isPrimaryButtonLoading.sink { [weak self] isLoading in
            guard let self = self else { return }
            self.primaryButton.isEnabled = !isLoading
            self.primaryButton.showActivityIndicator(isLoading)
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
}
