import UIKit

// MARK: - Contents

/// Details for each page of the login prologue carousel.
///
enum LoginProloguePageType: CaseIterable {
    case stats
    case orderManagement
    case products
    case reviews
    case getStarted

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
        case .reviews:
            return NSLocalizedString("Monitor and approve your product reviews",
                                     comment: "Caption displayed in promotional screens shown during the login flow.")
        case .getStarted:
            return NSLocalizedString("Sell anything, anywhere.",
                                     comment: "Caption displayed in the simplified prologue screen")
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
        case .getStarted:
            return NSLocalizedString("From your first sale to millions in revenue, Woo is with you. "
                                     + "See why merchants trust us to power 3.4 million online stores.",
                                     comment: "Subtitle displayed in the simplified prologue screen")
        default:
            return nil
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
        case .reviews:
            return UIImage.prologueReviewsImage
        case .getStarted:
            return UIImage.prologueWooMobileImage
        }
    }
}

// MARK: - View Controller

/// Simple container for each page of the login prologue carousel.
///
final class LoginProloguePageTypeViewController: UIViewController {
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let imageView = UIImageView()

    private let pageType: LoginProloguePageType
    private let showsSubtitle: Bool

    init(pageType: LoginProloguePageType, showsSubtitle: Bool) {
        self.pageType = pageType
        self.showsSubtitle = showsSubtitle

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view = UIView()
        view.backgroundColor = .clear

        configureStackView()
        configureImage()
        configureTitle()
        if showsSubtitle {
            configureSubtitle()
        }
    }
}

private extension LoginProloguePageTypeViewController {
    func configureStackView() {
        // Scroll view to contain all contents
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(scrollView, insets: .init(top: 0, left: 0, bottom: -Constants.stackBottomMargin, right: 0))
        scrollView.addSubview(stackView)

        // Stack view layout
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.stackSpacing


        // Set constraints
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.pinSubviewToAllEdges(stackView)
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    func configureImage() {
        stackView.addArrangedSubview(imageView)

        // Image style & layout
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: Constants.imageHeightMultiplier)
        ])

        // Image contents
        imageView.image = pageType.image
    }

    func configureTitle() {
        stackView.addArrangedSubview(titleLabel)

        // Label style & layout
        titleLabel.font = {
            if pageType == .getStarted {
                return .title3SemiBold
            } else if showsSubtitle {
                return .font(forStyle: .title2, weight: .semibold)
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
            titleLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: Constants.labelLeadingMargin)
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
        subtitleLabel.textColor = .textSubtle
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: Constants.labelLeadingMargin)
        ])

        subtitleLabel.text = pageType.subtitle
    }
}

private extension LoginProloguePageTypeViewController {
    enum Constants {
        static let stackSpacing: CGFloat = 40 // Space between image and text
        static let stackBottomMargin: CGFloat = -57 // Minimum margin between stack view and login buttons, including space required for UIPageControl
        static let imageHeightMultiplier: CGFloat = 0.35
        static let labelLeadingMargin: CGFloat = 48
    }
}
