
import UIKit
import WordPressAuthenticator
import SafariServices

final class JetPackErrorViewController: UIViewController {
    private let viewModel: ULErrorViewModel

    @IBOutlet private var primaryButton: NUXButton!
    @IBOutlet private var secondaryButton: NUXButton!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var extraInfoButton: UIButton!

    init(viewModel: ULErrorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureImageView()
        configureErrorMessage()
        configureExtraInfoButton()

        configurePrimaryButton()
        configureSecondaryButton()
    }
}


// MARK: - View configuration
private extension JetPackErrorViewController {
    func configureImageView() {
        imageView.image = viewModel.image
    }

    func configureErrorMessage() {
        errorMessage.attributedText = viewModel.text
    }

    func configureExtraInfoButton() {
        guard viewModel.isAuxiliaryButtonVisible else {
            extraInfoButton.isHidden = true

            return
        }

        extraInfoButton.applyLinkButtonStyle()
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

    func configureSecondaryButton() {
        secondaryButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
        secondaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapSecondaryButton()
        }
    }
}


// MARK: - Actions
private extension JetPackErrorViewController {
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
