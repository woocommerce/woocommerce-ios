import UIKit
import WordPressAuthenticator
import SafariServices


/// UI containing modals preented in the Card Present Payments flows.
final class CardPresentPaymentsModalViewController: UIViewController {
    /// The view model providing configuration for this view controller
    /// and support for user actions
    private var viewModel: CardPresentPaymentsModalViewModel

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet private weak var topTitleLabel: UILabel!
    @IBOutlet private weak var topSubtitleLabel: UILabel!
    @IBOutlet private weak var bottomTitleLabel: UILabel!
    @IBOutlet private weak var bottomSubtitleLabel: UILabel!

    @IBOutlet private weak var primaryButton: NUXButton!
    @IBOutlet private weak var secondaryButton: NUXButton!
    @IBOutlet weak var auxiliaryButton: UIButton!

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

        setBackgroundColor()
        setButtonsActions()
        styleContent()
        populateContent()
    }

    func setViewModel(_ newViewModel: CardPresentPaymentsModalViewModel) {
        self.viewModel = newViewModel

        populateContent()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact)) {
            mainStackView.axis = .horizontal
            mainStackView.distribution = .fillProportionally
        } else {
            mainStackView.axis = .vertical
            mainStackView.distribution = .fill
        }
    }
}


// MARK: - View configuration
private extension CardPresentPaymentsModalViewController {
    func setBackgroundColor() {
        containerView.backgroundColor = .tertiarySystemBackground
    }

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
        topTitleLabel.applyHeadlineStyle()
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
        styleAuxiliaryButton()
    }

    func stylePrimaryButton() {
        primaryButton.isPrimary = true
        primaryButton.titleLabel?.adjustsFontSizeToFitWidth = true
        primaryButton.titleLabel?.minimumScaleFactor = 0.5
    }

    func styleSecondaryButton() {
        secondaryButton.titleLabel?.adjustsFontSizeToFitWidth = true
        secondaryButton.titleLabel?.minimumScaleFactor = 0.5
    }

    func styleAuxiliaryButton() {
        auxiliaryButton.applyLinkButtonStyle()
        auxiliaryButton.titleLabel?.adjustsFontSizeToFitWidth = true
        auxiliaryButton.titleLabel?.minimumScaleFactor = 0.5
    }

    func populateContent() {
        configureTopTitle()

        if shouldShowTopSubtitle() {
            configureTopSubtitle()
        }

        configureImageView()

        if shouldShowActionButtons() {
            configureActionButtonsView()
        } else {
            hideActionButtonsView()
        }

        if shouldShowBottomLabels() {
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
        bottomLabels.isHidden = false

        configureBottomTitle()
        configureBottomSubtitle()
    }

    func configureBottomTitle() {
        bottomTitleLabel.text = viewModel.bottomTitle
    }

    func configureBottomSubtitle() {
        guard shouldShowBottomSubtitle() else {
            bottomSubtitleLabel.isHidden = true
            return
        }

        bottomSubtitleLabel.isHidden = false
        bottomSubtitleLabel.text = viewModel.bottomSubtitle
    }

    func configureImageView() {
        imageView.image = viewModel.image
    }

    func setButtonsActions() {
        primaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapPrimaryButton()
        }

        secondaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapSecondaryButton()
        }

        auxiliaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapAuxiliaryButton()
        }
    }

    func configureActionButtonsView() {
        actionButtonsView.isHidden = false
        bottomLabels.isHidden = true

        configurePrimaryButton()
        configureSecondaryButton()
        configureAuxiliaryButton()
    }

    func hideActionButtonsView() {
        actionButtonsView.isHidden = true
    }

    func configurePrimaryButton() {
        guard shouldShowActionButtons() else {
            primaryButton.isHidden = true
            return
        }

        primaryButton.isHidden = false
        primaryButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
    }

    func configureSecondaryButton() {
        guard shouldShowBottomActionButton() else {
            secondaryButton.isHidden = true
            return
        }

        secondaryButton.isHidden = false
        secondaryButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
    }

    func configureAuxiliaryButton() {
        guard shouldShowAuxiliaryButton() else {
            auxiliaryButton.isHidden = true
            return
        }

        auxiliaryButton.isHidden = false
        auxiliaryButton.setTitle(viewModel.auxiliaryButtonTitle, for: .normal)
    }
}

// MARK: - View layout configuration
private extension CardPresentPaymentsModalViewController {
    func shouldShowTopSubtitle() -> Bool {
        viewModel.textMode != .reducedTopInfo
    }

    func shouldShowBottomLabels() -> Bool {
        viewModel.textMode != .noBottomInfo
    }

    func shouldShowActionButtons() -> Bool {
        viewModel.actionsMode != .none
    }

    func shouldShowBottomSubtitle() -> Bool {
        let textMode = viewModel.textMode
        return textMode == .fullInfo ||
            textMode == .reducedTopInfo
    }

    func shouldShowBottomActionButton() -> Bool {
        let actionMode = viewModel.actionsMode

        return actionMode == .twoAction ||
            actionMode == .twoActionAndAuxiliary
    }

    func shouldShowAuxiliaryButton() -> Bool {
        viewModel.actionsMode == .twoActionAndAuxiliary
    }
}


// MARK: - Actions
private extension CardPresentPaymentsModalViewController {
    @objc func didTapPrimaryButton() {
        viewModel.didTapPrimaryButton(in: self)
    }

    @objc func didTapSecondaryButton() {
        viewModel.didTapSecondaryButton(in: self)
    }

    @objc func didTapAuxiliaryButton() {
        viewModel.didTapAuxiliaryButton(in: self)
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
    func getTopTitleLabel() -> UILabel {
        return topTitleLabel
    }

    func getTopSubtitleLabel() -> UILabel {
        return topSubtitleLabel
    }

    func getImageView() -> UIImageView {
        return imageView
    }

    func getBottomTitleLabel() -> UILabel {
        return bottomTitleLabel
    }

    func getBottomSubtitleLabel() -> UILabel {
        return bottomSubtitleLabel
    }

    func getPrimaryActionButton() -> UIButton {
        return primaryButton
    }

    func getSecondaryActionButton() -> UIButton {
        return secondaryButton
    }
}
