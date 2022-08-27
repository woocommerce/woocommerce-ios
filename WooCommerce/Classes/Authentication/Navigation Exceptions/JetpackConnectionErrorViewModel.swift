import Foundation
import WordPressAuthenticator

final class JetpackConnectionErrorViewModel: ULErrorViewModel {
    private let siteURL: String
    private var jetpackConnectionURL: URL?

    init(siteURL: String, credentials: WordPressOrgCredentials) {
        self.siteURL = siteURL
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
        guard let api = WordPressOrgAPI(credentials: credentials) else {
            return
        }

        Task { [weak self] in
            guard let self = self else { return }
            let data = try? await api.request(method: .get, path: Constants.jetpackConnectionFetchPath, parameters: nil)
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if let data = data, let escapedString = String(data: data, encoding: .utf8) {
                    let urlString = escapedString
                        .replacingOccurrences(of: "\"", with: "")
                        .replacingOccurrences(of: "\\", with: "")
                    self.jetpackConnectionURL = URL(string: urlString)
                }
            }
        }

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

    enum Constants {
        static let jetpackConnectionFetchPath = "/jetpack/v4/connection/url"
    }
}
