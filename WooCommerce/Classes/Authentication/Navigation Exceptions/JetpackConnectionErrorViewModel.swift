import Combine
import Foundation
import Yosemite
import WordPressAuthenticator
import class Networking.WordPressOrgNetwork

final class JetpackConnectionErrorViewModel: ULErrorViewModel {
    private let siteURL: String
    private var jetpackConnectionURL: URL?
    private let stores: StoresManager
    private let isPrimaryButtonLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let jetpackSetupCompletionHandler: (String?) -> Void

    init(siteURL: String,
         credentials: WordPressOrgCredentials,
         stores: StoresManager = ServiceLocator.stores,
         onJetpackSetupCompletion: @escaping (String?) -> Void) {
        self.siteURL = siteURL
        self.stores = stores
        self.jetpackSetupCompletionHandler = onJetpackSetupCompletion
        fetchJetpackConnectionURL()
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

    var isPrimaryButtonLoading: AnyPublisher<Bool, Never> {
        isPrimaryButtonLoadingSubject.eraseToAnyPublisher()
    }

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    func viewDidLoad(_ viewController: UIViewController?) {
        // TODO: Tracks?
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
        guard let url = jetpackConnectionURL else {
            DDLogWarn("⚠️ No Jetpack connection URL found")
            return
        }
        let viewModel = JetpackConnectionWebViewModel(initialURL: url, siteURL: siteURL, completion: { [weak self] in
            self?.fetchJetpackUser()
        })
        let pluginViewController = AuthenticatedWebViewController(viewModel: viewModel)
        viewController?.navigationController?.show(pluginViewController, sender: nil)
    }

    func authenticate(with credentials: WordPressOrgCredentials) {
        guard let authenticator = credentials.makeCookieNonceAuthenticator() else {
            return
        }
        let network = WordPressOrgNetwork(authenticator: authenticator)
        let action = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        stores.dispatch(action)
    }

    func fetchJetpackConnectionURL() {
        isPrimaryButtonLoadingSubject.send(true)
        let action = JetpackConnectionAction.fetchJetpackConnectionURL { [weak self] result in
            guard let self = self else { return }
            self.isPrimaryButtonLoadingSubject.send(false)
            switch result {
            case .success(let url):
                self.jetpackConnectionURL = url
            case .failure(let error):
                DDLogWarn("⚠️ Error fetching Jetpack connection URL: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Gets the connected WPcom email address if possible, or show error otherwise.
    ///
    func fetchJetpackUser() {
        let action = JetpackConnectionAction.fetchJetpackUser { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                guard let emailAddress = user.wpcomUser?.email else {
                    DDLogWarn("⚠️ Cannot find connected WPcom user")
                    // TODO: show error
                    return
                }
                self.jetpackSetupCompletionHandler(emailAddress)
            case .failure:
                // TODO: show error
                break
            }
        }
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
