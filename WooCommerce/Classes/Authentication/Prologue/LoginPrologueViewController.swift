import Foundation
import UIKit
import WordPressAuthenticator
import Experiments


/// Displays the WooCommerce Prologue UI.
///
final class LoginPrologueViewController: UIViewController {
    private let isNewToWooCommerceButtonShown: Bool
    private let isOnboardingFeatureEnabled: Bool
    private let analytics: Analytics

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

    init(analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        isNewToWooCommerceButtonShown = featureFlagService.isFeatureFlagEnabled(.newToWooCommerceLinkInLoginPrologue)
        self.isOnboardingFeatureEnabled = featureFlagService.isFeatureFlagEnabled(.loginPrologueOnboarding)
        self.analytics = analytics
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupBackgroundView()
        setupContainerView()
        setupCurvedRectangle()
        setupCarousel(isNewToWooCommerceButtonShown: isNewToWooCommerceButtonShown)
        setupNewToWooCommerceButton(isNewToWooCommerceButtonShown: isNewToWooCommerceButtonShown)
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
    func setupCarousel(isNewToWooCommerceButtonShown: Bool) {
        let pageTypes: [LoginProloguePageType] = isOnboardingFeatureEnabled ? [.getStarted]: LoginProloguePageType.allCases
        let carousel = LoginProloguePageViewController(pageTypes: pageTypes)
        carousel.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(carousel)
        view.addSubview(carousel.view)
        if isNewToWooCommerceButtonShown {
            NSLayoutConstraint.activate([
                carousel.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                carousel.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                carousel.view.topAnchor.constraint(equalTo: view.topAnchor),
                carousel.view.bottomAnchor.constraint(equalTo: newToWooCommerceButton.topAnchor,
                                                      constant: -Constants.spacingBetweenCarouselAndNewToWooCommerceButton),
            ])
        } else {
            view.pinSubviewToAllEdges(carousel.view)
        }
    }

    func setupNewToWooCommerceButton(isNewToWooCommerceButtonShown: Bool) {
        guard isNewToWooCommerceButtonShown else {
            return newToWooCommerceButton.isHidden = true
        }
        newToWooCommerceButton.setTitle(Localization.newToWooCommerce, for: .normal)
        newToWooCommerceButton.applyLinkButtonStyle()
        newToWooCommerceButton.titleLabel?.numberOfLines = 0
        newToWooCommerceButton.titleLabel?.textAlignment = .center
        newToWooCommerceButton.on(.touchUpInside) { [weak self] _ in
            guard let self = self else { return }

            self.analytics.track(.loginNewToWooButtonTapped)

            guard let url = URL(string: Constants.newToWooCommerceURL) else {
                return assertionFailure("Cannot generate URL.")
            }

            WebviewHelper.launch(url, with: self)
        }
    }
}

private extension LoginPrologueViewController {
    enum Constants {
        static let spacingBetweenCarouselAndNewToWooCommerceButton: CGFloat = 20
        static let newToWooCommerceURL = "https://woocommerce.com/document/woocommerce-features"
    }

    enum Localization {
        static let newToWooCommerce = NSLocalizedString("New to WooCommerce?",
                                                        comment: "Title of button in the login prologue screen for users who are new to WooCommerce.")
    }
}
