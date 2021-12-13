import UIKit

// MARK: - Contents

/// Details for each page of the login prologue carousel.
///
enum LoginProloguePageType: CaseIterable {
    case stats
    case orderManagement
    case products
    case reviews

    var title: String {
        switch self {
        case .stats:
            return NSLocalizedString("Track sales and high performing products",
                                     comment: "Caption displayed in promotional screens shown during the login flow.")
        case .orderManagement:
            return NSLocalizedString("Manage your store orders on the go ",
                                     comment: "Caption displayed in promotional screens shown during the login flow.")
        case .products:
            return NSLocalizedString("Edit and add new products from anywhere",
                                     comment: "Caption displayed in promotional screens shown during the login flow.")
        case .reviews:
            return NSLocalizedString("Monitor and approve your product reviews",
                                     comment: "Caption displayed in promotional screens shown during the login flow.")
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
        }
    }
}

// MARK: - View Controller

/// Simple container for each page of the login prologue carousel.
///
class LoginProloguePageTypeViewController: UIViewController {
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let imageView = UIImageView()

    private var pageType: LoginProloguePageType

    init(pageType: LoginProloguePageType) {
        self.pageType = pageType

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
    }

    private func configureStackView() {
        view.addSubview(stackView)

        // Stack view layout
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.stackSpacing

        // Reduce centerYAnchor constraint priority to ensure the bottom margin has higher priority, so stack view is fully visible on shorter devices
        let verticalCentering = stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: Constants.stackVerticalOffset)
        verticalCentering.priority = .required - 1

        // Set constraints
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            verticalCentering,
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: Constants.stackBottomMargin),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func configureImage() {
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

    private func configureTitle() {
        stackView.addArrangedSubview(titleLabel)

        // Label style & layout
        titleLabel.font = .body
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: Constants.labelWidth)
        ])

        // Label contents
        titleLabel.text = pageType.title
    }

    private enum Constants {
        static let stackSpacing: CGFloat = 40 // Space between image and text
        static let stackVerticalOffset: CGFloat = 103
        static let stackBottomMargin: CGFloat = -57 // Minimum margin between stack view and login buttons, including space required for UIPageControl
        static let imageHeightMultiplier: CGFloat = 0.35
        static let labelWidth: CGFloat = 216
    }
}
