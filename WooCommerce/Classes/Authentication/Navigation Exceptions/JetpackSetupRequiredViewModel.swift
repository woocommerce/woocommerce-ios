import Combine
import UIKit

/// Configuration and actions for an ULErrorViewController,
/// modeling an error when Jetpack is not installed or is not connected
/// Displayed as an entry point to the native Jetpack setup flow.
/// 
final class JetpackSetupRequiredViewModel: ULErrorViewModel {

    let siteURL: String
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private let connectionOnly: Bool
    private let authentication: Authentication
    private let analytics: Analytics
    private var coordinator: LoginJetpackSetupCoordinator?
    private var imageDownloadTask: ImageDownloadTask?

    @Published private var siteIcon = UIImage(systemName: "globe.americas.fill")

    init(siteURL: String,
         connectionOnly: Bool,
         authentication: Authentication = ServiceLocator.authenticationManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.connectionOnly = connectionOnly
        self.siteURL = siteURL
        self.authentication = authentication
        self.analytics = analytics
    }

    // MARK: - Data and configuration
    let title: String? = Localization.title

    var image: UIImage {
        connectionOnly ? .jetpackConnectionImage : .jetpackSetupImage
    }

    var text: NSAttributedString {
        let title = connectionOnly ? Localization.connectionErrorMessage : Localization.setupErrorMessage
        let message = NSMutableAttributedString(string: title, attributes: [.font: UIFont.title3, .foregroundColor: UIColor.text])

        let subtitle = Localization.setupSubtitle
        let subtitleAttributedString = NSAttributedString(string: "\n\n" + subtitle,
                                                          attributes: [.font: UIFont.body,
                                                                       .foregroundColor: UIColor.secondaryLabel])
        message.append(subtitleAttributedString)
        return message
    }

    let isAuxiliaryButtonHidden = true

    let auxiliaryButtonTitle = ""

    var primaryButtonTitle: String {
        connectionOnly ? Localization.connectJetpack : Localization.installJetpack
    }

    let secondaryButtonTitle = ""

    let isSecondaryButtonHidden = true

    let isSiteAddressViewHidden = false

    var siteFavicon: AnyPublisher<UIImage?, Never> {
        $siteIcon.eraseToAnyPublisher()
    }

    // Configures `Help` button title
    let rightBarButtonItemTitle: String? = Localization.helpBarButtonItemTitle

    var termsLabelText: NSAttributedString? {
        let content = String.localizedStringWithFormat(Localization.termsContent, Localization.termsOfService, Localization.shareDetails)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let mutableAttributedText = NSMutableAttributedString(
            string: content,
            attributes: [.font: UIFont.caption1,
                         .foregroundColor: UIColor.text,
                         .paragraphStyle: paragraph]
        )

        mutableAttributedText.setAsLink(textToFind: Localization.termsOfService,
                                        linkURL: Links.jetpackTerms + self.siteURL)
        mutableAttributedText.setAsLink(textToFind: Localization.shareDetails,
                                        linkURL: Links.jetpackShareDetails + self.siteURL)
        return mutableAttributedText
    }

    func viewDidLoad(_ viewController: UIViewController?) {
        if connectionOnly {
            analytics.track(.loginJetpackConnectionErrorShown)
        } else {
            analytics.track(.loginJetpackRequiredScreenViewed)
        }

        loadSiteFavicon()
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        if connectionOnly {
            analytics.track(.loginJetpackConnectButtonTapped)
        } else {
            analytics.track(.loginJetpackSetupButtonTapped)
        }

        guard let navigationController = viewController?.navigationController else {
            return
        }
        let coordinator = LoginJetpackSetupCoordinator(siteURL: siteURL,
                                                       connectionOnly: connectionOnly,
                                                       navigationController: navigationController)
        self.coordinator = coordinator
        coordinator.start()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        // no-op
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        // no-op
    }

    func didTapRightBarButtonItem(in viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }
        authentication.presentSupport(from: viewController, screen: .jetpackRequired)
    }
}

private extension JetpackSetupRequiredViewModel {
    func loadSiteFavicon() {
        guard let url = URL(string: siteURL + Links.favicoPath) else {
            return
        }
        imageDownloadTask = ServiceLocator.imageService.downloadImage(with: url, shouldCacheImage: true) { [weak self] image, _ in
            self?.siteIcon = image ?? UIImage(systemName: "globe.americas.fill")
        }
    }
}

extension JetpackSetupRequiredViewModel {
    enum Localization {
        static let title = NSLocalizedString("Connect Store", comment: "Title of the Jetpack setup required screen")
        static let installJetpack = NSLocalizedString(
            "Install Jetpack",
            comment: "Button to install Jetpack from the Jetpack setup required screen"
        )
        static let connectJetpack = NSLocalizedString(
            "Connect Jetpack",
            comment: "Button to authorize Jetpack connection from the Jetpack setup required screen"
        )
        static let setupErrorMessage = NSLocalizedString(
            "Please install the free Jetpack plugin to access your store on this app.",
            comment: "Error message on the Jetpack setup required screen."
        )
        static let connectionErrorMessage = NSLocalizedString(
            "Please connect your store to Jetpack to access it on this app.",
            comment: "Error message on the Jetpack setup required screen when Jetpack connection is missing."
        )
        static let setupSubtitle = NSLocalizedString(
            "Have your store credentials ready.",
            comment: "Subtitle on the Jetpack setup required screen"
        )
        static let helpBarButtonItemTitle = NSLocalizedString("Help", comment: "Help button on Jetpack setup required screen.")
        static let termsContent = NSLocalizedString(
            "By tapping the Connect Jetpack button, you agree to our %1$@ and to %2$@ with WordPress.com.",
            comment: "Content of the label at the end of the Jetpack setup required screen. " +
            "Reads like: By tapping the Connect Jetpack button, you agree to our Terms of Service and to share details with WordPress.com."
        )
        static let termsOfService = NSLocalizedString(
            "Terms of Service",
            comment: "The terms to be agreed upon when tapping the Connect Jetpack button on the Jetpack setup required screen."
        )
        static let shareDetails = NSLocalizedString(
            "share details",
            comment: "The action to be agreed upon when tapping the Connect Jetpack button on the Jetpack setup required screen."
        )
    }

    enum Links {
        static let jetpackTerms = "https://jetpack.com/redirect/?source=wpcom-tos&site="
        static let jetpackShareDetails = "https://jetpack.com/redirect/?source=jetpack-support-what-data-does-jetpack-sync&site="
        static let favicoPath = "/favicon.ico"
    }
}
