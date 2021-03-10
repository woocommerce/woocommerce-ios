import UIKit

/// Displays information about shipping label creation, including the benefits.
final class ShippingLabelCreationInfoViewController: UIViewController {
    /// Empty state screen
    private lazy var emptyStateViewController = EmptyStateViewController(style: .basic)

    /// Empty state screen configuration
    private let emptyStateConfig: EmptyStateViewController.Config = {
        let message = NSAttributedString(string: Constants.message,
                                         attributes: [.font: EmptyStateViewController.Config.messageFont.bold])
        return .withLink(message: message,
                         image: .shippingLabelCreationInfoImage,
                         details: Constants.details,
                         linkTitle: Constants.buttonTitle,
                         linkURL: WooConstants.URLs.shippingLabelCreationInfo.asURL())
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureEmptyViewController()
    }
}

// MARK: Constants
private extension ShippingLabelCreationInfoViewController {
    func configureNavigationBar() {
        title = Constants.title
        addCloseNavigationBarButton()
    }

    func configureEmptyViewController() {
        addChild(emptyStateViewController)

        emptyStateViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateViewController.view)

        emptyStateViewController.view.pinSubviewToAllEdges(view)
        emptyStateViewController.didMove(toParent: self)
        emptyStateViewController.configure(emptyStateConfig)
    }
}

// MARK: Constants
private extension ShippingLabelCreationInfoViewController {
    struct Constants {
        static let title = NSLocalizedString("WooCommerce Shipping",
                                             comment: "Navigation bar title in the shipping label creation info screen")
        static let message = NSLocalizedString("Save time and money by fulfilling with WooCommerce Shipping",
                                               comment: "Message text in the shipping label creation info screen")
        static let details = NSLocalizedString("Cut the post office line by printing shipping labels at home with your phone at discounted rates!",
                                               comment: "Details text in the shipping label creation info screen")
        static let buttonTitle = NSLocalizedString("Learn more",
                                                   comment: "Button title in the shipping label creation info screen")
    }
}
