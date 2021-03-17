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

    private var pageType: LoginProloguePageType!

    init(pageType: LoginProloguePageType) {
        self.pageType = pageType

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear

        configureStackView()
        configureImage()
        configureTitle()
    }

    private func configureStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        // Stack view style
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 40
        view.pinSubviewToSafeArea(stackView, insets: UIEdgeInsets(top: 190, left: 70, bottom: 110, right: 70))
    }

    private func configureImage() {
        stackView.addArrangedSubview(imageView)

        // Image style
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // Image contents
        imageView.image = pageType.image
    }

    private func configureTitle() {
        stackView.addArrangedSubview(titleLabel)

        // Label style
        titleLabel.font = .body
        titleLabel.textColor = .text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -10)
        ])

        // Label contents
        titleLabel.text = pageType.title
    }
}
