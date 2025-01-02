import UIKit

// MARK: - Contents

/// Details for each page of the login prologue carousel.
///
enum LoginOnboardingPageType: CaseIterable {
    case stats
    case orderManagement
    case products

    var title: String {
        switch self {
        case .stats:
            return NSLocalizedString("Track sales and high performing products",
                                     comment: "Caption displayed in promotional screens shown during the login flow.")
        case .orderManagement:
            return NSLocalizedString("Manage and edit orders on the go",
                                     comment: "Caption displayed in promotional screens shown during the login flow.")
        case .products:
            return NSLocalizedString("Edit and add new products from anywhere",
                                     comment: "Caption displayed in promotional screens shown during the login flow.")
        }
    }

    var subtitle: String? {
        switch self {
        case .stats:
            return NSLocalizedString("We know it’s essential to your business.",
                                     comment: "Subtitle displayed in promotional screens shown during the login flow.")
        case .orderManagement:
            return NSLocalizedString("You can manage quickly and easily.",
                                     comment: "Subtitle displayed in promotional screens shown during the login flow.")
        case .products:
            return NSLocalizedString("We enable you to process them effortlessly.",
                                     comment: "Subtitle displayed in promotional screens shown during the login flow.")
        }
    }

    var image: UIImage {
        switch self {
        case .stats:
            return UIImage.prologueAnalyticsImage
        case .orderManagement:
            return UIImage.prologueOrdersImage
        case .products:
            return UIImage.prologueProductsImage
        }
    }
}

// MARK: - View Controller

/// Simple container for each page of the login prologue carousel.
///
final class LoginOnboardingPageTypeViewController: UIViewController {
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let imageView = UIImageView()

    private let pageType: LoginOnboardingPageType
    private let showsSubtitle: Bool

    init(pageType: LoginOnboardingPageType, showsSubtitle: Bool) {
        self.pageType = pageType
        self.showsSubtitle = showsSubtitle

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view = UIView()
        view.backgroundColor = .clear

        configureStackView()
        configureImage()
        configureTitle()
        if showsSubtitle {
            configureSubtitle()
        }
        configureSpacers()
    }
}

private extension LoginOnboardingPageTypeViewController {
    func configureStackView() {
        // Scroll view to contain all contents
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(scrollView)
        scrollView.addSubview(stackView)

        // Stack view layout
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.stackSpacing


        // Set constraints
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor).isActive = true
        scrollView.pinSubviewToAllEdges(stackView, insets: .init(top: 0, left: Constants.stackViewPadding, bottom: 0, right: Constants.stackViewPadding))
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -Constants.stackViewPadding * 2),
        ])
    }

    func configureImage() {
        stackView.addArrangedSubview(imageView)

        // Image style & layout
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])

        // Image contents
        imageView.image = pageType.image

        stackView.setCustomSpacing(4 * Constants.stackSpacing, after: imageView)
    }

    func configureTitle() {
        stackView.addArrangedSubview(titleLabel)

        // Label style & layout
        titleLabel.font = {
            if showsSubtitle {
                return .font(forStyle: .title1, weight: .bold)
            } else {
                return .body
            }
        }()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.labelMaxWidth),
        ])

        // Label contents
        titleLabel.text = pageType.title
        titleLabel.accessibilityIdentifier = "prologue-title-label"
    }

    func configureSubtitle() {
        stackView.addArrangedSubview(subtitleLabel)

        // Label style & layout
        subtitleLabel.font = .body
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .text
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.labelMaxWidth),
        ])

        subtitleLabel.text = pageType.subtitle
    }

    /// Add spacers to the top and bottom of the stack view to ensure the contents are centered in the scroll view when content fits on screen.
    func configureSpacers() {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.insertArrangedSubview(spacer, at: 0)

        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(bottomSpacer)

        spacer.heightAnchor.constraint(equalTo: bottomSpacer.heightAnchor).isActive = true
    }
}

private extension LoginOnboardingPageTypeViewController {
    enum Constants {
        static let labelMaxWidth: CGFloat = 333
        static let stackSpacing: CGFloat = 8 // Space between image and text
        static let stackViewPadding: CGFloat = 16
    }
}
