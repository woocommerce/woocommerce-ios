import Foundation
import UIKit
import WordPressAuthenticator


/// Displays the WooCommerce Prologue UI.
///
final class LoginPrologueViewController: UIViewController {

    /// Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet private var backgroundView: UIView!

    /// Container View: Holds up the Button + bottom legend.
    ///
    @IBOutlet private var containerView: UIView!

    /// Curved Rectangle: Background shape with curved top edge
    ///
    @IBOutlet private weak var curvedRectangle: UIImageView!

    /// Button for users who are new to WooCommerce to learn more about WooCommerce.
    @IBOutlet private weak var newToWooCommerceButton: UIButton!

    // MARK: - Overridden Properties

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupBackgroundView()
        setupContainerView()
        setupCurvedRectangle()
        setupCarousel()
        setupNewToWooCommerceButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}


// MARK: - Initialization Methods
//
private extension LoginPrologueViewController {

    func setupMainView() {
        view.backgroundColor = .basicBackground
    }

    func setupBackgroundView() {
        backgroundView.backgroundColor = .authPrologueBottomBackgroundColor
    }

    func setupContainerView() {
        containerView.backgroundColor = .authPrologueBottomBackgroundColor
    }

    func setupCurvedRectangle() {
        curvedRectangle.image = UIImage.curvedRectangle.withRenderingMode(.alwaysTemplate)
        curvedRectangle.tintColor = .authPrologueBottomBackgroundColor
    }

    /// Adds a carousel (slider) of screens to promote the main features of the app.
    /// This is contained in a child view so that this view's background doesn't scroll.
    ///
    func setupCarousel() {
        let carousel = LoginProloguePageViewController()
        carousel.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(carousel)
        view.addSubview(carousel.view)
        NSLayoutConstraint.activate([
            carousel.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carousel.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carousel.view.topAnchor.constraint(equalTo: view.topAnchor),
            carousel.view.bottomAnchor.constraint(equalTo: newToWooCommerceButton.topAnchor),
        ])
    }

    func setupNewToWooCommerceButton() {
        newToWooCommerceButton.setTitle(Localization.newToWooCommerce, for: .normal)
        newToWooCommerceButton.applyLinkButtonStyle()
        newToWooCommerceButton.titleLabel?.numberOfLines = 0
        newToWooCommerceButton.on(.touchUpInside) { _ in
            // TODO: 7231 - analytics

            guard let url = URL(string: Constants.newToWooCommerceURL) else {
                return assertionFailure("Cannot generate URL.")
            }

            WebviewHelper.launch(url, with: self)
        }
    }
}

private extension LoginPrologueViewController {
    enum Constants {
        // TODO: 7231 - update URL if needed
        static let newToWooCommerceURL = "https://wordpress.com/support/introduction-to-woocommerce"
    }

    enum Localization {
        static let newToWooCommerce = NSLocalizedString("New to WooCommerce?",
                                                        comment: "Title of button in the login prologue screen for users who are new to WooCommerce.")
    }
}
