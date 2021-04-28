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
        if shouldShowTopSubtitle() {
            styleTopSubtitle()
        }

        if shouldShowBottomLabels() {
            styleBottomLabels()
        }

        if shouldShowActionButtons() {
            styleActionButtons()
        }
    }

    func styleTopTitle() {
        topTitleLabel.applyBodyStyle()
    }

    func styleTopSubtitle() {
        topSubtitleLabel.applyTitleStyle()
    }

    func styleBottomLabels() {
        actionButtonsView.isHidden = true
        bottomLabels.isHidden = false

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
        actionButtonsView.isHidden = false
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

        if shouldShowTopSubtitle() {
            configureTopSubtitle()
        }

        configureImageView()

        if shouldShowActionButtons() {
            configureActionButtonsView()
        }

        if !shouldShowActionButtons() {
            configureBottomLabels()
        }
    }

    func configureTopTitle() {
        topTitleLabel.text = viewModel.topTitle
    }

    func configureTopSubtitle() {
        topSubtitleLabel.text = viewModel.topSubtitle
    }

    func configureBottomLabels() {
        print("==== hiding bottom buttoms")
        actionButtonsView.isHidden = true
        bottomLabels.isHidden = false

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
        actionButtonsView.isHidden = false
        bottomLabels.isHidden = true

        configurePrimaryButton()
        configureSecondaryButton()
    }

    func configurePrimaryButton() {
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

// MARK: - View layout configuration
private extension CardPresentPaymentsModalViewController {
    func shouldShowTopSubtitle() -> Bool {
        viewModel.mode != .reducedInfo
    }

    func shouldShowBottomLabels() -> Bool {
        let mode = viewModel.mode
        return mode == .fullInfo ||
            mode == .reducedInfo
    }

    func shouldShowActionButtons() -> Bool {
        let mode = viewModel.mode
        return mode == .oneActionButton ||
            mode == .twoActionButtons ||
            mode == .reducedInfoOneActionButton
    }
}


// MARK: - Actions
private extension CardPresentPaymentsModalViewController {
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
