import UIKit

/// Configurable UI properties for `InProgressViewController`.
///
struct InProgressViewProperties {
    let title: String
    let message: String
}

/// Used to indicate a task is in progress and prevent other user interactions.
///
final class InProgressViewController: UIViewController {
    @IBOutlet private weak var backgroundVisualEffectView: UIVisualEffectView!
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var messageLabel: UILabel!

    private let viewProperties: InProgressViewProperties

    init(viewProperties: InProgressViewProperties) {
        self.viewProperties = viewProperties

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isModalInPresentation = true

        configureBackgroundView()
        configureStackView()
        configureTitle()
        configureActivityIndicator()
        configureMessage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicatorView.startAnimating()
    }
}

private extension InProgressViewController {
    func configureBackgroundView() {
        view.backgroundColor = .clear

        let blurEffect = UIBlurEffect(style: .dark)
        backgroundVisualEffectView.effect = blurEffect
    }

    func configureStackView() {
        contentStackView.alignment = .center
        contentStackView.spacing = 24
    }

    func configureTitle() {
        titleLabel.applyHeadlineStyle()
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        titleLabel.text = viewProperties.title
    }

    func configureActivityIndicator() {
        activityIndicatorView.style = .medium
        activityIndicatorView.color = .gray(.shade10)
    }

    func configureMessage() {
        messageLabel.applyFootnoteStyle()
        messageLabel.textColor = .gray(.shade10)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        messageLabel.text = viewProperties.message
    }
}
