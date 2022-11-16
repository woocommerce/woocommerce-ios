import Combine
import UIKit

/// Configuration and actions for an ULErrorViewController,
/// modeling an error when Jetpack is not installed or is not connected
/// Displayed as an entry point to the native Jetpack setup flow.
/// 
struct JetpackSetupRequiredViewModel: ULErrorViewModel {
    private let siteURL: String
    private let connectionOnly: Bool
    private let authentication: Authentication
    private let analytics: Analytics

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
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL.trimHTTPScheme(),
                                                           attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: connectionOnly ? Localization.connectionErrorMessage : Localization.setupErrorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        let subtitle = connectionOnly ? Localization.connectionSubtitle : Localization.setupSubtitle
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

    // Configures `Help` button title
    let rightBarButtonItemTitle: String? = Localization.helpBarButtonItemTitle

    var termsLabelText: AnyPublisher<NSAttributedString, Never> {
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
                                        linkURL: Strings.jetpackTermsURL + self.siteURL)
        mutableAttributedText.setAsLink(textToFind: Localization.shareDetails,
                                        linkURL: Strings.jetpackShareDetailsURL + self.siteURL)
        return Just(mutableAttributedText).eraseToAnyPublisher()
    }

    func viewDidLoad(_ viewController: UIViewController?) {
        // TODO: add tracks
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        // TODO: handle Jetpack setup natively
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
            "To use this app for %@ you'll need the free Jetpack plugin installed and connected on your store.",
            comment: "Error message on the Jetpack setup required screen." +
            "Reads like: To use this app for test.com you'll need...")
        static let connectionErrorMessage = NSLocalizedString(
            "To use this app for %@ you'll need to connect your store to Jetpack.",
            comment: "Error message on the Jetpack setup required screen when Jetpack connection is missing." +
            "Reads like: To use this app for test.com you'll need...")
        static let setupSubtitle = NSLocalizedString(
            "You’ll need your store credentials to begin the installation.",
            comment: "Subtitle on the Jetpack setup required screen"
        )
        static let connectionSubtitle = NSLocalizedString(
            "You’ll need your store credentials to begin the connection.",
            comment: "Subtitle on the Jetpack setup required screen when only Jetpack connection is missing"
        )
        static let helpBarButtonItemTitle = NSLocalizedString("Help", comment: "Help button on Jetpack setup required screen.")
        static let termsContent = NSLocalizedString(
            "By tapping the Connect Jetpack button, you agree to our %1$@ and to %2$@ with WordPress.com.",
            comment: "Content of the label at the end of the Jetpack setup required screen. " +
            "Reads like: By tapping the Connect Jetpack button, you agree to our Terms of Service and to share details with WordPress.com.")
        static let termsOfService = NSLocalizedString(
            "Terms of Service",
            comment: "The terms to be agreed upon when tapping the Connect Jetpack button on the Jetpack setup required screen."
        )
        static let shareDetails = NSLocalizedString(
            "share details",
            comment: "The action to be agreed upon when tapping the Connect Jetpack button on the Jetpack setup required screen."
        )
    }

    enum Strings {
        static let jetpackTermsURL = "https://jetpack.com/redirect/?source=wpcom-tos&site="
        static let jetpackShareDetailsURL = "https://jetpack.com/redirect/?source=jetpack-support-what-data-does-jetpack-sync&site="
    }
}
