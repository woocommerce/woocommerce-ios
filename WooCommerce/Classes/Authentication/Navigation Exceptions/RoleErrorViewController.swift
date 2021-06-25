import UIKit
import WordPressAuthenticator

class RoleErrorViewController: UIViewController {
    // MARK: IBOutlets

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkButton: UIButton!

    @IBOutlet weak var primaryActionButton: UIButton!
    @IBOutlet weak var secondaryActionButton: UIButton!

    // MARK: Properties

    let viewModel: RoleErrorViewModel

    // MARK: Lifecycle

    init(viewModel: RoleErrorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
    }

    // MARK: View Configurations

    /// styles up the views. this should ideally only be called once.
    func configureViews() {
        // top title labels
        titleLabel.applyHeadlineStyle()
        subtitleLabel.applySecondaryFootnoteStyle()
        updateTitleLabels()

        // illustration
        imageView.image = viewModel.image

        // description
        configureDescriptionLabel()

        // button configurations
        configureLinkButton()
        configurePrimaryActionButton()
        configureSecondaryActionButton()
    }

    /// this method may be repeatedly called by the view model to update text contents.
    /// these are the only components that may change on runtime, e.g. the role changed
    /// to something else, but still incorrect; or the user updated their display name.
    func updateTitleLabels() {
        titleLabel.text = viewModel.nameText
        subtitleLabel.text = viewModel.roleText
    }

    func configureDescriptionLabel() {
        descriptionLabel.applyBodyStyle()
        descriptionLabel.attributedText = .init(string: viewModel.descriptionText)
    }

    func configureLinkButton() {
        linkButton.applyLinkButtonStyle()
        linkButton.setTitle(viewModel.auxiliaryButtonTitle, for: .normal)
        linkButton.on(.touchUpInside) { [weak self] _ in
            self?.viewModel.didTapAuxiliaryButton()
        }
    }

    func configurePrimaryActionButton() {
        primaryActionButton.applyPrimaryButtonStyle()
        primaryActionButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        primaryActionButton.on(.touchUpInside) { [weak self] _ in
            self?.viewModel.didTapPrimaryButton()
        }
    }

    func configureSecondaryActionButton() {
        secondaryActionButton.applySecondaryButtonStyle()
        secondaryActionButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
        secondaryActionButton.on(.touchUpInside) { [weak self] _ in
            self?.viewModel.didTapSecondaryButton()
        }
    }

    // MARK: Trait Change Adjustments

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // hide image in compact height sizes (e.g. landscape iphones).
        // with limited space, text description should have higher priority.
        imageView.isHidden = traitCollection.verticalSizeClass == .compact

        // handle dynamic color appearance changes.
        if let previousTrait = previousTraitCollection,
           previousTrait.hasDifferentColorAppearance(comparedTo: traitCollection) {
            updateViewAppearances()
        }
    }

    /// update views that can adjust to color appearance changes.
    /// this method is called when color appearance changes are detected in `traitCollectionDidChange`.
    private func updateViewAppearances() {
        // illustrations
        imageView.image = viewModel.image

        // buttons
        primaryActionButton.applyPrimaryButtonStyle()
        secondaryActionButton.applySecondaryButtonStyle()
    }
}
