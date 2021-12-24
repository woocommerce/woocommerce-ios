import UIKit
import SafariServices
import WordPressAuthenticator

/// RoleErrorOutput enables communication from the view model to the view controller.
/// Note that it's important for the view model to weakly retain the view controller.
protocol RoleErrorOutput: AnyObject {
    /// Updates title and subtitle label text with latest content.
    func refreshTitleLabels()

    /// Tells the output to display a web content.
    func displayWebContent(for url: URL)

    func displayNotice(message: String)
}

// MARK: - View Controller

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

    private let viewModel: RoleErrorViewModel

    override var preferredStatusBarStyle: UIStatusBarStyle {
        traitCollection.userInterfaceStyle == .light ? .darkContent : .lightContent
    }

    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    // MARK: Lifecycle

    init(viewModel: RoleErrorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
        viewModel.output = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar()
    }

    // MARK: View Configurations

    func configureNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    /// styles up the views. this should ideally only be called once.
    func configureViews() {
        // set up navigation items
        addHelpButtonToNavigationItem()

        // top title labels
        titleLabel.applyHeadlineStyle()
        subtitleLabel.applySecondaryFootnoteStyle()
        refreshTitleLabels()

        // illustration
        imageView.image = viewModel.image

        // description
        configureDescriptionLabel()

        // button configurations
        configureLinkButton()
        configurePrimaryActionButton()
        configureSecondaryActionButton()
    }

    func configureDescriptionLabel() {
        descriptionLabel.applyBodyStyle()
        descriptionLabel.attributedText = .init(string: viewModel.descriptionText)
    }

    func configureLinkButton() {
        linkButton.applyLinkButtonStyle(enableMultipleLines: true)
        linkButton.titleLabel?.textAlignment = .center
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

    // MARK: Private helpers

    private func addHelpButtonToNavigationItem() {
        let helpBarButtonItem = UIBarButtonItem(title: viewModel.helpBarButtonTitle,
                                                style: .plain,
                                                target: self,
                                                action: #selector(helpButtonWasPressed))
        navigationItem.rightBarButtonItem = helpBarButtonItem
    }

    @objc private func helpButtonWasPressed() {
        ServiceLocator.authenticationManager.presentSupport(from: self, sourceTag: .generalLogin)
    }
}

// MARK: - RoleErrorOutput

extension RoleErrorViewController: RoleErrorOutput {
    func refreshTitleLabels() {
        // these are the only components that may change on runtime, e.g. the role changed
        // to something else, but still incorrect; or the user updated their display name.
        titleLabel.text = viewModel.titleText
        subtitleLabel.text = viewModel.subtitleText
    }

    func displayWebContent(for url: URL) {
        WebviewHelper.launch(url, with: self)
    }

    func displayNotice(message: String) {
        let notice = Notice(title: message)
        noticePresenter.enqueue(notice: notice)
    }
}
