import Foundation
import UIKit
import WordPressAuthenticator
import Experiments


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

    /// The WooCommerce logo on top of the screen
    @IBOutlet private weak var topLogoImageView: UIImageView!

    @IBOutlet private weak var titleLabel: UILabel!

    @IBOutlet private weak var subtitleLabel: UILabel!

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

        setupBackgroundViews()
        setupLabels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}


// MARK: - Initialization Methods
//
private extension LoginPrologueViewController {

    func setupBackgroundViews() {
        view.backgroundColor = .systemBackground
        backgroundView.backgroundColor = .clear
        containerView.backgroundColor = .clear
    }

    func setupLabels() {
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .title3.bold
        titleLabel.textColor = .text
        titleLabel.text = Localization.title

        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = .subheadline
        subtitleLabel.textColor = .text
        subtitleLabel.text = Localization.subtitle
    }
}

private extension LoginPrologueViewController {
    enum Constants {
        static let spacingBetweenTopLogoAndCarousel: CGFloat = 56
    }

    enum Localization {
        static let title = NSLocalizedString(
            "The e-commerce platform that grows with you",
            comment: "Caption displayed in the simplified prologue screen"
        )
        static let subtitle = NSLocalizedString(
            "Start with our 15-day free trial, no credit card needed. "
            + "Join 3.4M stores thriving with Woo, from first sale to millions.",
            comment: "Subtitle displayed in the simplified prologue screen"
        )
    }
}
