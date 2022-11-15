import UIKit

/// Configuration and actions for an ULErrorViewController,
/// modelling an error when Jetpack is not installed or is not connected
/// Displayed as an entry point to the native Jetpack setup flow.
/// 
struct JetpackSetupRequiredViewModel: ULErrorViewModel {
    private let siteURL: String
    private let connectionOnly: Bool

    init(siteURL: String, connectionOnly: Bool) {
        self.connectionOnly = connectionOnly
        self.siteURL = siteURL
    }

    // MARK: - Data and configuration
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

        return message
    }

    let isAuxiliaryButtonHidden = true

    let auxiliaryButtonTitle = ""

    var primaryButtonTitle: String {
        connectionOnly ? Localization.connectJetpack : Localization.installJetpack
    }

    let secondaryButtonTitle = ""

    let isSecondaryButtonHidden = true

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

}

extension JetpackSetupRequiredViewModel {
    enum Localization {
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
    }
}
