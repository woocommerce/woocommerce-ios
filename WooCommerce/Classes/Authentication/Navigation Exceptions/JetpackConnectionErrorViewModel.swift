import Foundation
import Yosemite
import WordPressAuthenticator

final class JetpackConnectionErrorViewModel: ULErrorViewModel {
    private let siteURL: String
    private var jetpackConnectionURL: URL?
    private let stores: StoresManager

    init(siteURL: String, credentials: WordPressOrgCredentials, stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.stores = stores
        fetchJetpackConnectionURL(with: credentials)
    }

    // MARK: - Data and configuration

    let image: UIImage = .productErrorImage
    
    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL.trimHTTPScheme(),
                                                           attributes: [.font: boldFont])
        let attributedString = NSMutableAttributedString(string: Localization.noJetpackEmail)
        attributedString.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return attributedString
    }
    
    let isAuxiliaryButtonHidden = true
    
    let auxiliaryButtonTitle = ""
    
    let primaryButtonTitle = Localization.primaryButtonTitle
    
    let secondaryButtonTitle = Localization.secondaryButtonTitle
    
    func viewDidLoad(_ viewController: UIViewController?) {
        // no-op
    }
    
    func didTapPrimaryButton(in viewController: UIViewController?) {
        showJetpackConnectionWebView(from: viewController)
    }
    
    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.navigationController?.popToRootViewController(animated: true)
    }
    
    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        // no-op
    }
}

// MARK: - Private helpers
private extension JetpackConnectionErrorViewModel {
    func showJetpackConnectionWebView(from viewController: UIViewController?) {
        guard let url = jetpackConnectionURL,
              let viewController = viewController else {
            return
        }
        WebviewHelper.launch(url, with: viewController)
    }

    func fetchJetpackConnectionURL(with credentials: WordPressOrgCredentials) {
        guard let authenticator = credentials.makeCookieNonceAuthenticator() else {
            return
        }
        let action = JetpackConnectionAction.fetchJetpackConnectionURL(siteURL: credentials.siteURL,
                                                                       authenticator: authenticator,
                                                                       completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                self.jetpackConnectionURL = url
            case .failure(let error):
                DDLogWarn("⚠️ Error fetching Jetpack connection URL: \(error)")
            }
        })
        stores.dispatch(action)
    }
}

private extension JetpackConnectionErrorViewModel {
    enum Localization {
        static let noJetpackEmail = NSLocalizedString(
            "It looks like your account is not connected to %@'s Jetpack",
            comment: "Message explaining that the entered site credentials belong to an account that is not connected to the site's Jetpack. "
            + "Reads like 'It looks like your account is not connected to awebsite.com's Jetpack")

        static let primaryButtonTitle = NSLocalizedString(
            "Connect Jetpack to your account",
            comment: "Button linking to web view for setting up Jetpack connection. " +
            "Presented when logging in with store credentials of an account not connected to the site's Jetpack")

        static let secondaryButtonTitle = NSLocalizedString(
            "Log In With Another Account",
            comment: "Action button that will restart the login flow." +
            "Presented when logging in with store credentials of an account not connected to the site's Jetpack"
        )
    }
}
