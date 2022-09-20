import UIKit
import SafariServices
import Combine
import WordPressUI
import Yosemite
import WordPressAuthenticator
import class Networking.WordPressOrgNetwork

/// Configuration and actions for an ULErrorViewController, modelling
/// an error when Jetpack is not installed or is not connected
final class WrongAccountErrorViewModel: ULAccountMismatchViewModel {

    private let siteURL: String
    private let showsConnectedStores: Bool
    private let defaultAccount: Account?
    private let storesManager: StoresManager
    private let analytics: Analytics
    private let jetpackSetupCompletionHandler: (_ email: String, _ xmlrpc: String) -> Void

    private var storePickerCoordinator: StorePickerCoordinator?
    private var siteXMLRPC: String = ""
    private var siteUsername: String = ""
    private var jetpackConnectionURL: URL?

    private let primaryButtonHiddenSubject = CurrentValueSubject<Bool, Never>(true)
    private let primaryButtonLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let activityIndicatorLoadingSubject = CurrentValueSubject<Bool, Never>(false)

    init(siteURL: String?,
         showsConnectedStores: Bool,
         siteCredentials: WordPressOrgCredentials?,
         sessionManager: SessionManagerProtocol =  ServiceLocator.stores.sessionManager,
         storesManager: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onJetpackSetupCompletion: @escaping (String, String) -> Void) {
        self.siteURL = siteURL ?? Localization.yourSite
        self.showsConnectedStores = showsConnectedStores
        self.defaultAccount = sessionManager.defaultAccount
        self.storesManager = storesManager
        self.analytics = analytics
        self.jetpackSetupCompletionHandler = onJetpackSetupCompletion

        if let credentials = siteCredentials {
            siteUsername = credentials.username
            siteXMLRPC = credentials.xmlrpc
            authenticate(with: credentials)
            fetchJetpackConnectionURL()
        }
    }

    // MARK: - Data and configuration
    var userEmail: String {
        return defaultAccount?.email ?? ""
    }

    var userName: String {
        return defaultAccount?.displayName ?? siteUsername
    }

    var signedInText: String {
        return String.localizedStringWithFormat(Localization.signedInMessageFormat,
                                                defaultAccount?.username ?? siteUsername)
    }

    let logOutTitle: String = Localization.wrongAccountMessage

    let logOutButtonTitle: String = Localization.logOutButtonTitle

    let image: UIImage = .productErrorImage

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL.trimHTTPScheme(),
                                                           attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }

    let isAuxiliaryButtonHidden = false

    let auxiliaryButtonTitle = Localization.findYourConnectedEmail

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    var isPrimaryButtonHidden: AnyPublisher<Bool, Never> {
        primaryButtonHiddenSubject.eraseToAnyPublisher()
    }

    var isPrimaryButtonLoading: AnyPublisher<Bool, Never> {
        primaryButtonLoadingSubject.eraseToAnyPublisher()
    }

    var isSecondaryButtonHidden: Bool { !showsConnectedStores }

    var isShowingActivityIndicator: AnyPublisher<Bool, Never> {
        activityIndicatorLoadingSubject.eraseToAnyPublisher()
    }

    // MARK: - Actions
    func viewDidLoad(_ viewController: UIViewController?) {
        analytics.track(event: .LoginJetpackConnection.jetpackConnectionErrorShown(selfHostedSite: true))

        // Fetches site info if we're not sure whether the site is self-hosted.
        if siteXMLRPC.isEmpty {
            fetchSiteInfo()
        } else {
            // Shows the Connect Jetpack button if the site is self-hosted
            primaryButtonHiddenSubject.send(false)
        }
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        analytics.track(.loginJetpackConnectButtonTapped)
        guard let viewController = viewController else {
            return
        }

        guard let url = jetpackConnectionURL else {
            return showSiteCredentialLoginAndJetpackConnection(from: viewController)
        }

        showJetpackConnectionWebView(url: url, from: viewController)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        guard let navigationController = viewController?.navigationController else {
            return
        }

        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .listStores)
        storePickerCoordinator?.start()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        let fancyAlert = FancyAlertViewController.makeNeedHelpFindingEmailAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        viewController?.present(fancyAlert, animated: true)
    }

    func didTapLogOutButton(in viewController: UIViewController?) {
        // Log out and pop
        storesManager.deauthenticate()
        viewController?.navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - Private helpers
private extension WrongAccountErrorViewModel {
    /// Fetches the site info and show the primary button if the site is self-hosted.
    /// This will enables Jetpack connection support for self-hosted sites.
    ///
    func fetchSiteInfo() {
        activityIndicatorLoadingSubject.send(true)
        WordPressAuthenticator.fetchSiteInfo(for: siteURL) { [weak self] result in
            guard let self = self else { return }
            self.activityIndicatorLoadingSubject.send(false)

            switch result {
            case .success(let siteInfo):
                if siteInfo.isWPCom == false {
                    self.primaryButtonHiddenSubject.send(false)
                }
            case .failure(let error):
                DDLogWarn("⚠️ Error fetching site info: \(error)")
            }
        }
    }

    /// Prepares `JetpackConnectionStore` to authenticate subsequent requests to WP.org API.
    ///
    func authenticate(with credentials: WordPressOrgCredentials) {
        guard let authenticator = credentials.makeCookieNonceAuthenticator() else {
            return
        }
        let network = WordPressOrgNetwork(authenticator: authenticator)
        let action = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        storesManager.dispatch(action)
    }

    /// Fetches the URL for handling Jetpack connection in a web view
    ///
    func fetchJetpackConnectionURL(onCompletion: ((URL) -> Void)? = nil) {
        primaryButtonLoadingSubject.send(true)
        let action = JetpackConnectionAction.fetchJetpackConnectionURL { [weak self] result in
            guard let self = self else { return }
            self.primaryButtonLoadingSubject.send(false)
            switch result {
            case .success(let url):
                onCompletion?(url)
                self.jetpackConnectionURL = url
            case .failure(let error):
                self.analytics.track(.loginJetpackConnectionURLFetchFailed, withError: error)
                DDLogWarn("⚠️ Error fetching Jetpack connection URL: \(error)")
            }
        }
        storesManager.dispatch(action)
    }

    func showSiteCredentialLoginAndJetpackConnection(from viewController: UIViewController) {
        WordPressAuthenticator.showSiteCredentialLogin(from: viewController, siteURL: siteURL) { [weak self] credentials in
            guard let self = self else { return }
            // dismisses the site credential login flow
            viewController.dismiss(animated: true)

            self.siteXMLRPC = credentials.xmlrpc
            self.authenticate(with: credentials)
            self.fetchJetpackConnectionURL { [weak self] url in
                self?.showJetpackConnectionWebView(url: url, from: viewController)
            }
        }
    }

    /// Presents a web view pointing to the Jetpack connection URL.
    ///
    func showJetpackConnectionWebView(url: URL, from viewController: UIViewController) {
        let viewModel = JetpackConnectionWebViewModel(initialURL: url, siteURL: siteURL, completion: { [weak self] in
            self?.fetchJetpackUser(in: viewController)
        })
        let pluginViewController = AuthenticatedWebViewController(viewModel: viewModel)
        viewController.navigationController?.show(pluginViewController, sender: nil)
    }

    /// Gets the connected WP.com email address if possible, or show error otherwise.
    ///
    func fetchJetpackUser(in viewController: UIViewController) {
        showInProgressView(in: viewController)
        let action = JetpackConnectionAction.fetchJetpackUser { [weak self] result in
            guard let self = self else { return }
            // dismisses the in-progress view
            viewController.navigationController?.dismiss(animated: true)

            switch result {
            case .success(let user):
                guard let emailAddress = user.wpcomUser?.email else {
                    DDLogWarn("⚠️ Cannot find connected WPcom user")
                    self.analytics.track(.loginJetpackConnectionVerificationFailed)
                    return self.showSetupErrorNotice(in: viewController)
                }

                if self.defaultAccount?.email == emailAddress {
                    // if user has already logged in with a WP.com account, show the store picker.
                    self.showStorePickerForLogin(in: viewController.navigationController)
                } else {
                    self.jetpackSetupCompletionHandler(emailAddress, self.siteXMLRPC)
                }

            case .failure(let error):
                DDLogWarn("⚠️ Error fetching Jetpack user: \(error)")
                self.analytics.track(.loginJetpackConnectionVerificationFailed, withError: error)
                self.showSetupErrorNotice(in: viewController)
            }
        }
        storesManager.dispatch(action)
    }

    func showStorePickerForLogin(in navigationController: UINavigationController?) {
        guard let navigationController = navigationController else {
            return
        }
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .login)

        // Tries re-syncing to get an updated store list
        storesManager.synchronizeEntities { [weak self] in
            guard let self = self else { return }
            let matcher = ULAccountMatcher()
            matcher.refreshStoredSites()
            guard let matchedSite = matcher.matchedSite(originalURL: self.siteURL) else {
                DDLogWarn("⚠️ Could not find \(self.siteURL) connected to the account")
                return
            }
            self.storePickerCoordinator?.didSelectStore(with: matchedSite.siteID, onCompletion: {})
        }
    }

    func showInProgressView(in viewController: UIViewController) {
        let viewProperties = InProgressViewProperties(title: Localization.inProgressMessage, message: "")
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext

        viewController.navigationController?.present(inProgressViewController, animated: true, completion: nil)
    }

    func showSetupErrorNotice(in viewController: UIViewController) {
        let message = Localization.setupErrorMessage
        let notice = Notice(title: message, feedbackType: .error)
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = viewController
        noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Private data structures
private extension WrongAccountErrorViewModel {
    enum Localization {
        static let signedInMessageFormat = NSLocalizedString("Signed in as @%1$@",
                                                             comment: "Message describing the account a user has signed in to."
                                                                + "Reads as: Signed is as @{username}"
                                                                + "Parameters: %1$@ - user name")

        static let errorMessage = NSLocalizedString("It looks like %@ is connected to a different account.",
                                                    comment: "Message explaining that the site entered and the acount logged into do not match. "
                                                        + "Reads like 'It looks like awebsite.com is connected to a different account")

        static let findYourConnectedEmail = NSLocalizedString("Find your connected email",
                                                     comment: "Button linking to webview explaining how to find your connected email"
                                                        + "Presented when logging in with a store address that does not match the account entered")

        static let logOutButtonTitle = NSLocalizedString("Log Out",
                                                          comment: "Action button triggering a Log Out."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let secondaryButtonTitle = NSLocalizedString("See Connected Stores",
                                                          comment: "Action button linking to a list of connected stores."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let primaryButtonTitle = NSLocalizedString("Connect Jetpack",
                                                          comment: "Action button to handle Jetpack connection."
                                                          + "Presented when logging in with a self-hosted site that does not match the account entered")

        static let yourSite = NSLocalizedString("your site",
                                                comment: "Placeholder for site url, if the url is unknown."
                                                    + "Presented when logging in with a store address that does not match the account entered.")

        static let wrongAccountMessage = NSLocalizedString("Wrong account?",
                                                           comment: "Prompt asking users if the logged in to the wrong account."
                                                               + "Presented when logging in with a store address that does not match the account entered.")

        static let inProgressMessage = NSLocalizedString(
            "Verifying Jetpack connection...",
            comment: "Message displayed when checking whether Jetpack has been connected successfully"
        )

        static let setupErrorMessage = NSLocalizedString(
            "Cannot verify your Jetpack connection. Please try again.",
            comment: "Error message displayed when failed to check for Jetpack connection."
        )

    }

    enum Strings {
        static let instructionsURLString = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"
    }
}
