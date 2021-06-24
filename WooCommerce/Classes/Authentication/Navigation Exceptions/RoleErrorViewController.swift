import UIKit
import WordPressAuthenticator

class RoleErrorViewController: UIViewController {

    // MARK: IBOutlets

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkButton: UIButton!

    @IBOutlet weak var primaryActionButton: NUXButton!
    @IBOutlet weak var secondaryActionButton: NUXButton!

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
        subtitleLabel.applyFootnoteStyle()
        updateTitleLabels()

        // center illustration
        imageView.image = viewModel.image

        // description
        descriptionLabel.applyBodyStyle()
        descriptionLabel.attributedText = viewModel.text

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

}
