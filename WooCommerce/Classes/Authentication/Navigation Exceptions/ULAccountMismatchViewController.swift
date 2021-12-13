import UIKit
import WordPressAuthenticator
import SafariServices


/// UI presenting errors in the Unified Login flow.
/// This view controller can either be presented from within WooCommerce
/// or be injected into WordPressAuthenticator.
final class ULAccountMismatchViewController: UIViewController {
    /// The view model providing configuration for this view controller
    /// and support for user actions
    private let viewModel: ULAccountMismatchViewModel

    /// Header View: Displays all of the Account Details
    ///
    private let accountHeaderView: AccountHeaderView = {
        return AccountHeaderView.instantiateFromNib()
    }()

    @IBOutlet private weak var gravatarImageView: CircularImageView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var singedInAsLabel: UILabel!
    @IBOutlet private weak var wrongAccountLabel: UILabel!
    @IBOutlet private weak var logOutButton: UIButton!
    @IBOutlet private weak var primaryButton: NUXButton!
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.isPad() ? .all : .portrait
    }

    init(viewModel: ULAccountMismatchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAccountHeader()
        configureImageView()
        configureErrorMessage()
        configureExtraInfoButton()

        configurePrimaryButton()

        setUnifiedMargins(forWidth: view.frame.width)
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
private extension ULAccountMismatchViewController {
    func configureAccountHeader() {
        configureGravatar()
        configureUserNameLabel()
        configureSignedInAsLabel()
        configureWrongAccountLabel()
        configureLogOutButton()
    }

    func configureGravatar() {
        gravatarImageView.downloadGravatarWithEmail(viewModel.userEmail)
    }

    func configureUserNameLabel() {
        userNameLabel.applyBodyStyle()
        userNameLabel.text = viewModel.userName
    }

    func configureSignedInAsLabel() {
        singedInAsLabel.applySecondaryBodyStyle()
        singedInAsLabel.text = viewModel.signedInText
    }

    func configureWrongAccountLabel() {
        wrongAccountLabel.applySecondaryBodyStyle()
        wrongAccountLabel.text = viewModel.logOutTitle
    }

    func configureLogOutButton() {
        logOutButton.applyLinkButtonStyle()
        logOutButton.setTitle(viewModel.logOutButtonTitle, for: .normal)
        logOutButton.contentEdgeInsets = .zero
        logOutButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapLogOutButton()
        }
    }

    func configureImageView() {
        imageView.image = viewModel.image
    }

    func configureErrorMessage() {
        errorMessage.applyBodyStyle()
        errorMessage.attributedText = viewModel.text
    }

    func configureExtraInfoButton() {
        extraInfoButton.applyLinkButtonStyle()
        extraInfoButton.contentEdgeInsets = Constants.extraInfoCustomInsets
        extraInfoButton.setTitle(viewModel.auxiliaryButtonTitle, for: .normal)
        extraInfoButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapAuxiliaryButton()
        }
    }

    func configurePrimaryButton() {
        primaryButton.isPrimary = true
        primaryButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        primaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapPrimaryButton()
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
private extension ULAccountMismatchViewController {
    func didTapAuxiliaryButton() {
        viewModel.didTapAuxiliaryButton(in: self)
    }

    func didTapPrimaryButton() {
        viewModel.didTapPrimaryButton(in: self)
    }

    func didTapLogOutButton() {
        viewModel.didTapLogOutButton(in: self)
    }
}


// MARK: - Constants
private extension ULAccountMismatchViewController {
    enum Constants {
        static let extraInfoCustomInsets = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
    }
}

// MARK: - Tests
extension ULAccountMismatchViewController {
    func getImageView() -> UIImageView {
        return imageView
    }

    func getMessage() -> UILabel {
        return errorMessage
    }

    func getAuxiliaryButton() -> UIButton {
        return extraInfoButton
    }

    func getLogOutButton() -> UIButton {
        return logOutButton
    }

    func getPrimaryActionButton() -> UIButton {
        return primaryButton
    }

    func getUserNameLabel() -> UILabel {
        return userNameLabel
    }

    func getSingedInAsLabel() -> UILabel {
        return singedInAsLabel
    }

    func getWrongAccountLabel() -> UILabel {
        return wrongAccountLabel
    }
}
