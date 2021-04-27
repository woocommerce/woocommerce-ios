import UIKit
import WordPressAuthenticator
import SafariServices


/// UI containing modals preented in the Card Present Payments flows.
final class CardPresentPaymentsModalViewController: UIViewController {
    /// The view model providing configuration for this view controller
    /// and support for user actions
    private var viewModel: CardPresentPaymentsModalViewModel

    @IBOutlet private weak var topTitleLabel: UILabel!
    @IBOutlet private weak var topSubtitleLabel: UILabel!
    @IBOutlet private weak var bottomTitleLabel: UILabel!
    @IBOutlet private weak var bottomSubtitleLabel: UILabel!

    @IBOutlet private weak var primaryButton: NUXButton!
    @IBOutlet private weak var secondaryButton: NUXButton!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var extraInfoButton: UIButton!

    @IBOutlet private weak var actionButtonsView: UIView!
    @IBOutlet private weak var bottomLabels: UIStackView!


    init(viewModel: CardPresentPaymentsModalViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        styleContent()
        populateContent()
    }

    func setViewModel(_ newViewModel: CardPresentPaymentsModalViewModel) {
        self.viewModel = newViewModel

        populateContent()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
}


// MARK: - View configuration
private extension CardPresentPaymentsModalViewController {

    func styleContent() {
        styleTopTitle()
        styleTopSubtitle()
        styleBottomLabels()
        styleActionButtons()
    }

    func styleTopTitle() {
        topTitleLabel.applyBodyStyle()
    }

    func styleTopSubtitle() {
        topSubtitleLabel.applyTitleStyle()
    }

    func styleBottomLabels() {
        guard viewModel.areButtonsVisible == false else {
            bottomLabels.isHidden = true
            actionButtonsView.isHidden = false
            return
        }

        styleBottomTitle()
        styleBottomSubtitle()
    }

    func styleBottomTitle() {
        bottomTitleLabel.applyBodyStyle()
    }

    func styleBottomSubtitle() {
        bottomSubtitleLabel.applyFootnoteStyle()
    }

    func styleActionButtons() {
        guard viewModel.areButtonsVisible == true else {
            bottomLabels.isHidden = false
            actionButtonsView.isHidden = true
            return
        }

        bottomLabels.isHidden = true
        stylePrimaryButton()
        styleSecondaryButton()
    }

    func stylePrimaryButton() {
        primaryButton.isPrimary = true
    }

    func styleSecondaryButton() {

    }

    func populateContent() {
        configureTopTitle()
        configureTopSubtitle()

        configureImageView()

        configureActionButtonsView()
        configureBottomLabels()

        configureExtraInfoButton()

        configurePrimaryButton()
        configureSecondaryButton()
    }

    func configureTopTitle() {
        topTitleLabel.text = viewModel.topTitle
    }

    func configureTopSubtitle() {
        topSubtitleLabel.text = viewModel.topSubtitle
    }

    func configureBottomLabels() {
        guard viewModel.areButtonsVisible == false else {
            bottomLabels.isHidden = true
            actionButtonsView.isHidden = false
            return
        }

        configureBottomTitle()
        configureBottomSubtitle()
    }

    func configureBottomTitle() {
        bottomTitleLabel.text = viewModel.bottomTitle
    }

    func configureBottomSubtitle() {
        bottomSubtitleLabel.text = viewModel.bottomSubtitle
    }

    func configureImageView() {
        imageView.image = viewModel.image
    }

//    func configureErrorMessage() {
//        errorMessage.applyBodyStyle()
//        errorMessage.text = viewModel.topTitle
//    }

    func configureActionButtonsView() {
        guard viewModel.areButtonsVisible == true else {
            bottomLabels.isHidden = false
            actionButtonsView.isHidden = true
            return
        }

        bottomLabels.isHidden = true
        configureExtraInfoButton()
        configurePrimaryButton()
        configureSecondaryButton()
    }

    func configureExtraInfoButton() {
        guard viewModel.isAuxiliaryButtonHidden == false else {
            extraInfoButton.isHidden = true

            return
        }

        extraInfoButton.applyLinkButtonStyle()
        extraInfoButton.contentEdgeInsets = Constants.extraInfoCustomInsets
        extraInfoButton.setTitle(viewModel.auxiliaryButtonTitle, for: .normal)
        extraInfoButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapAuxiliaryButton()
        }
    }

    func configurePrimaryButton() {
        //primaryButton.isPrimary = true
        primaryButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        primaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapPrimaryButton()
        }
    }

    func configureSecondaryButton() {
        secondaryButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
        secondaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapSecondaryButton()
        }
    }
}


// MARK: - Actions
private extension CardPresentPaymentsModalViewController {
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
private extension CardPresentPaymentsModalViewController {
    enum Constants {
        static let extraInfoCustomInsets = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
    }
}

// MARK: - Tests
extension CardPresentPaymentsModalViewController {
    func getImageView() -> UIImageView {
        return imageView
    }

//    func getLabel() -> UILabel {
//        return errorMessage
//    }

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
