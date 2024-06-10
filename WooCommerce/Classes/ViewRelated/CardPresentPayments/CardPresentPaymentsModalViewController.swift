import UIKit
import SwiftUI
import WordPressAuthenticator
import SafariServices


/// UI containing modals presented in the Card Present Payments flows.
final class CardPresentPaymentsModalViewController: UIViewController, CardReaderModalFlowViewControllerProtocol {
    /// The view model providing configuration for this view controller
    /// and support for user actions
    private var viewModel: CardPresentPaymentsModalViewModel

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var bottomPaddingRegular: NSLayoutConstraint!
    @IBOutlet weak var primaryActionButtonsStackView: UIStackView!
    @IBOutlet weak var buttonsSpacer: UIView!
    @IBOutlet private weak var topTitleLabel: UILabel!
    @IBOutlet private weak var topSubtitleLabel: UILabel!
    @IBOutlet private weak var bottomTitleLabel: UILabel!
    @IBOutlet private weak var bottomSubtitleLabel: UILabel!

    @IBOutlet private weak var primaryButton: UIButton!
    @IBOutlet private weak var secondaryButton: UIButton!
    @IBOutlet weak var auxiliaryButton: UIButton!

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var extraInfoButton: UIButton!

    @IBOutlet private weak var actionButtonsView: UIView!
    @IBOutlet private weak var bottomLabels: UIStackView!

    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!

    private var loadingView: UIView?

    init(viewModel: CardPresentPaymentsModalViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createViews()
        initializeContent()
        setBackgroundColor()
        setButtonsActions()
        styleContent()
        populateContent()
    }

    func setViewModel(_ newViewModel: CardPresentPaymentsModalViewModel) {
        self.viewModel = newViewModel

        if isViewLoaded {
            populateContent()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        resetHeightAndWidth()
    }

    private func resetHeightAndWidth() {
        if traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact)) {
            primaryActionButtonsStackView.axis = .horizontal
            primaryActionButtonsStackView.distribution = .fillProportionally

            mainStackView.distribution = .fillProportionally
            heightConstraint.constant = Constants.modalWidth
            widthConstraint.constant = Constants.modalHeight
        } else {
            primaryActionButtonsStackView.axis = .vertical
            primaryActionButtonsStackView.distribution = .fill

            mainStackView.distribution = .fill
            heightConstraint.constant = Constants.modalHeight
            widthConstraint.constant = Constants.modalWidth
        }

        updateImageAndLoadingVisibility()

        heightConstraint.priority = .required
        widthConstraint.priority = .required
        configureSpacer()
    }

    private func updateImageAndLoadingVisibility() {
        if traitCollection.containsTraits(in: UITraitCollection(verticalSizeClass: .compact)) {
            imageView.isHidden = true
            loadingView?.isHidden = true
        } else {
            if viewModel.showLoadingIndicator {
                imageView.isHidden = true
                loadingView?.isHidden = false
            } else {
                imageView.isHidden = false
                loadingView?.isHidden = true
            }
        }
    }
}


// MARK: - View configuration
private extension CardPresentPaymentsModalViewController {
    func setBackgroundColor() {
        containerView.backgroundColor = .tertiarySystemBackground
    }

    func createViews() {
        createLoadingIndicator()
    }

    func createLoadingIndicator() {
        let loadingIndicator = ProgressView()
            .progressViewStyle(IndefiniteCircularProgressViewStyle(size: 96.0))
            .padding()
        let host = ConstraintsUpdatingHostingController(rootView: loadingIndicator)
        host.view.backgroundColor = .tertiarySystemBackground
        add(host)

        guard let index = mainStackView.arrangedSubviews.firstIndex(of: imageView) else {
            return
        }
        mainStackView.insertArrangedSubview(host.view, at: index)
        loadingView = host.view
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
        topTitleLabel.applyBodyStyle()
    }

    func styleTopSubtitle() {
        topSubtitleLabel.applyTitleStyle()
    }

    func styleBottomLabels() {
        actionButtonsView.isHidden = true
        bottomLabels.isHidden = false
        configureSpacer()

        styleBottomTitle()
        styleBottomSubtitle()
    }

    func styleBottomTitle() {
        bottomTitleLabel.applySubheadlineStyle()
    }

    func styleBottomSubtitle() {
        bottomSubtitleLabel.applyFootnoteStyle()
    }

    func styleActionButtons() {
        actionButtonsView.isHidden = false
        bottomLabels.isHidden = true
        configureSpacer()

        stylePrimaryButton()
        styleSecondaryButton()
        styleAuxiliaryButton()
    }

    func stylePrimaryButton() {
        primaryButton.applyPrimaryButtonStyle()
        primaryButton.titleLabel?.adjustsFontSizeToFitWidth = true
        primaryButton.titleLabel?.minimumScaleFactor = 0.5
    }

    func styleSecondaryButton() {
        secondaryButton.applyPaymentsModalCancelButtonStyle()
        secondaryButton.titleLabel?.adjustsFontSizeToFitWidth = true
        secondaryButton.titleLabel?.minimumScaleFactor = 0.5
    }

    func styleAuxiliaryButton() {
        if viewModel.actionsMode != .secondaryActionAndAuxiliaryButton {
            auxiliaryButton.applyLinkButtonStyle()
        }
        auxiliaryButton.titleLabel?.minimumScaleFactor = 0.5
        auxiliaryButton.titleLabel?.adjustsFontSizeToFitWidth = true
    }

    func initializeContent() {
        topTitleLabel.text = ""
        topSubtitleLabel.text = ""
        bottomTitleLabel.text = ""
        bottomSubtitleLabel.text = ""
    }

    func populateContent() {
        configureAccessibility()
        configureTopTitle()

        if shouldShowTopSubtitle() {
            configureTopSubtitle()
        }

        configureImageView()

        if shouldShowActionButtons() {
            configureActionButtonsView()
            styleActionButtons()
        } else {
            hideActionButtonsView()
        }

        if shouldShowBottomLabels() {
            configureBottomLabels()
        }

        resetHeightAndWidth()
    }

    func configureTopTitle() {
        topTitleLabel.text = viewModel.topTitle
        topTitleLabel.accessibilityIdentifier = Accessibility.topTitleLabel
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
        configureSpacer()
    }

    func configurePrimaryButton() {
        guard shouldShowPrimaryActionButton() else {
            primaryButton.isHidden = true
            return
        }

        primaryButton.isHidden = false
        primaryButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        primaryButton.accessibilityIdentifier = Accessibility.primaryButton
    }

    func configureSecondaryButton() {
        guard shouldShowBottomActionButton() else {
            secondaryButton.isHidden = true
            return
        }

        secondaryButton.isHidden = false
        secondaryButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
        secondaryButton.accessibilityIdentifier = Accessibility.secondaryButton
    }

    func configureAuxiliaryButton() {

        guard shouldShowAuxiliaryButton() else {
            auxiliaryButton.isHidden = true
            return
        }

        auxiliaryButton.isHidden = false
        auxiliaryButton.accessibilityIdentifier = Accessibility.auxiliaryButton
        // Prevents UI flicker when loading different content
        UIView.performWithoutAnimation {
            auxiliaryButton.setTitle(viewModel.auxiliaryButtonTitle, for: .normal)
            auxiliaryButton.setAttributedTitle(viewModel.auxiliaryAttributedButtonTitle, for: .normal)
            var config = UIButton.Configuration.plain()
            config.contentInsets = Constants.auxiliaryButtonInsets
            config.titleAlignment = .leading
            auxiliaryButton.configuration = config
            view.layoutIfNeeded()
        }
    }

    func configureSpacer() {
        let enabled = !shouldShowActionButtons()

        if isRegularClassSize {
            buttonsSpacer.isHidden = true
            // For iPads, instead of a flexible spacer we expand the bottom margin with an extra 127px.
            // This would be the space equivalents to the primary and secondary buttons being visible
            // - 32px of spacing between buttons container and the rest of the content
            // - 40px for the primary button
            // - 15px of spacing between buttons
            // - 40px for the secondary button
            bottomPaddingRegular.constant = 42 + (enabled ? 127 : 0)
        } else {
            // For compact screens (iPhones, or iPad in split mode), we us a flexible spacer with a low
            // content hugging priority to ensure it takes all the available space, leaving the rest of
            // the visible items aligned to the top of the stack view
            buttonsSpacer.isHidden = !enabled
        }
    }

    var isRegularClassSize: Bool {
        traitCollection.verticalSizeClass == .regular && traitCollection.horizontalSizeClass == .regular
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

    func shouldShowPrimaryActionButton() -> Bool {
        [.oneAction, .twoAction, .twoActionAndAuxiliary]
            .contains(viewModel.actionsMode)
    }

    func shouldShowBottomActionButton() -> Bool {
        [.secondaryOnlyAction, .twoAction, .twoActionAndAuxiliary, .secondaryActionAndAuxiliaryButton]
            .contains(viewModel.actionsMode)
    }

    func shouldShowAuxiliaryButton() -> Bool {
        [.twoActionAndAuxiliary, .secondaryActionAndAuxiliaryButton].contains(viewModel.actionsMode)
    }
}

// MARK: - Accessibility
private extension CardPresentPaymentsModalViewController {
    func configureAccessibility() {
        accessibilityTraits = .staticText
        UIAccessibility.post(notification: .announcement, argument: viewModel.accessibilityLabel)
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
        static let modalHeight: CGFloat = 382
        static let modalWidth: CGFloat = 280
        static let auxiliaryButtonInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
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

private extension CardPresentPaymentsModalViewController {
    enum Accessibility {
        static let topTitleLabel = "card-present-payments-modal-title-label"
        static let primaryButton = "card-present-payments-modal-primary-button"
        static let secondaryButton = "card-present-payments-modal-secondary-button"
        static let auxiliaryButton = "card-present-payments-modal-auxiliary-button"
    }
}
