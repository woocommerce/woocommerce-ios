import Foundation
import UIKit
import WordPressAuthenticator
import Experiments
import protocol WooFoundation.Analytics


/// Displays the WooCommerce Prologue UI.
///
final class LoginPrologueViewController: UIViewController {

    private let analytics: Analytics
    private let featureFlagService: FeatureFlagService

    /// Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet private var backgroundView: UIView!

    /// Container View: Holds up the Button + bottom legend.
    ///
    @IBOutlet private var containerView: UIView!

    /// Curved Rectangle: Background shape with curved top edge
    ///
    @IBOutlet private weak var curvedRectangle: UIImageView!

    /// The WooCommerce logo on top of the screen
    @IBOutlet private weak var topLogoImageView: UIImageView!

    // MARK: - Overridden Properties

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    // MARK: - Overridden Methods

    init(analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.analytics = analytics
        self.featureFlagService = featureFlagService
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
        setupCarousel()
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
        view.backgroundColor = .systemBackground
    }

    func setupBackgroundView() {
        backgroundView.backgroundColor = .systemBackground
    }

    func setupContainerView() {
        containerView.backgroundColor = .systemBackground
    }

    func setupCurvedRectangle() {
        curvedRectangle.isHidden = true
    }

    /// Adds a carousel (slider) of screens to promote the main features of the app.
    /// This is contained in a child view so that this view's background doesn't scroll.
    ///
    func setupCarousel() {
        let pageTypes: [LoginProloguePageType] = [.getStarted]
        let carousel = LoginProloguePageViewController(pageTypes: pageTypes, showsSubtitle: true)
        carousel.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(carousel)
        view.addSubview(carousel.view)
        NSLayoutConstraint.activate([
            carousel.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carousel.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carousel.view.topAnchor.constraint(equalTo: topLogoImageView.bottomAnchor, constant: Constants.spacingBetweenTopLogoAndCarousel),
            carousel.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.bringSubviewToFront(topLogoImageView)
    }
}

private extension LoginPrologueViewController {
    enum Constants {
        static let spacingBetweenTopLogoAndCarousel: CGFloat = -16
    }
}
