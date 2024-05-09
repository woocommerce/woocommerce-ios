import UIKit
import SafariServices
import Combine
import WordPressUI
import Yosemite
import WordPressAuthenticator
import class Networking.WordPressOrgNetwork
import protocol WooFoundation.Analytics

/// Configuration and actions for an ULErrorViewController, modelling
/// an error when Jetpack is not installed or is not connected
final class WrongAccountErrorViewModel: ULAccountMismatchViewModel {

    private let siteURL: String
    private let showsConnectedStores: Bool
    private let defaultAccount: Account?
    private let storesManager: StoresManager
    private let analytics: Analytics
    private let jetpackSetupCompletionHandler: (_ email: String, _ xmlrpc: String) -> Void
    private let authentication: Authentication
    private let authenticatorType: Authenticator.Type

    private var storePickerCoordinator: StorePickerCoordinator?
    private var jetpackSetupCoordinator: LoginJetpackSetupCoordinator?

    private var siteXMLRPC: String = ""
    private var siteUsername: String = ""

    @Published private var isSelfHostedSite = false
    @Published private var primaryButtonLoading = false
    @Published private var termsAttributedString: NSAttributedString = .init(string: "")

    private var siteInfoSubscription: AnyCancellable?

    init(siteURL: String?,
         showsConnectedStores: Bool,
         siteCredentials: WordPressOrgCredentials?,
         authenticatorType: Authenticator.Type = WordPressAuthenticator.self,
         storesManager: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         authentication: Authentication = ServiceLocator.authenticationManager,
         onJetpackSetupCompletion: @escaping (String, String) -> Void) {
        self.siteURL = siteURL ?? Localization.yourSite
        self.showsConnectedStores = showsConnectedStores
        self.defaultAccount = storesManager.sessionManager.defaultAccount
        self.storesManager = storesManager
        self.analytics = analytics
        self.authentication = authentication
        self.jetpackSetupCompletionHandler = onJetpackSetupCompletion
        self.authenticatorType = authenticatorType

        if let credentials = siteCredentials {
            siteUsername = credentials.username
            siteXMLRPC = credentials.xmlrpc
        }
    }

    // MARK: - Data and configuration
    var userEmail: String {
        defaultAccount?.email ?? ""
    }

    var userName: String {
        defaultAccount?.displayName ?? siteUsername
    }

    var signedInText: String {
        String.localizedStringWithFormat(Localization.signedInMessageFormat,
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

    var termsLabelText: AnyPublisher<NSAttributedString, Never> {
        $termsAttributedString.eraseToAnyPublisher()
    }

    let isAuxiliaryButtonHidden = false

    let auxiliaryButtonTitle = Localization.findYourConnectedEmail

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    var isPrimaryButtonLoading: AnyPublisher<Bool, Never> {
        $primaryButtonLoading.eraseToAnyPublisher()
    }

    var isSecondaryButtonHidden: Bool { !showsConnectedStores }


    // Configures `Help` button title
    var rightBarButtonItemTitle: String? {
        Localization.helpBarButtonItemTitle
    }

    // MARK: - Actions
    func viewDidLoad(_ viewController: UIViewController?) {

        trackScreenView()
        configureTermsText()

        // Fetches site info if we're not sure whether the site is self-hosted.
        if siteXMLRPC.isEmpty {
            fetchSiteInfo()
        } else {
            isSelfHostedSite = true
        }
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        analytics.track(.loginJetpackConnectButtonTapped)
        guard let viewController = viewController else {
            return
        }

        if isSelfHostedSite {
            return showSiteCredentialLoginAndJetpackConnection(from: viewController)
        }
        return presentConnectToWPComSiteAlert(from: viewController)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        guard let navigationController = viewController?.navigationController else {
            return
        }

        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .listStores)
        storePickerCoordinator?.start()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        let fancyAlert = FancyAlertViewController.makeNeedHelpFindingEmailAlertController(screen: .wrongAccountError)
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        viewController?.present(fancyAlert, animated: true)
    }

    func didTapLogOutButton(in viewController: UIViewController?) {
        // Log out and pop
        storesManager.deauthenticate()
        viewController?.navigationController?.popToRootViewController(animated: true)
    }

    func didTapRightBarButtonItem(in viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }
        authentication.presentSupport(from: viewController, screen: .wrongAccountError)
    }
}

// MARK: - Private helpers
private extension WrongAccountErrorViewModel {
    /// Waits for site info to log the screen view.
    ///
    func trackScreenView() {
        siteInfoSubscription = $isSelfHostedSite
            .dropFirst() // ignores first element
            .sink { [weak self] isSelfHosted in
                self?.analytics.track(event: .LoginJetpackConnection.jetpackConnectionErrorShown(selfHostedSite: isSelfHosted))
            }
    }

    /// Listens to changes to the self-hosted site check to update the content of the terms text.
    ///
    func configureTermsText() {
        $isSelfHostedSite
            .map { [weak self] isSelfHosted -> NSMutableAttributedString in
                // only shows terms text if the site is self-hosted,
                // since the user cannot handle Jetpack connection themselves on WP.com sites.
                guard let self, isSelfHosted else {
                    return .init(string: "")
                }
                let content = String.localizedStringWithFormat(Localization.termsContent, Localization.termsOfService, Localization.shareDetails)
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center

                let mutableAttributedText = NSMutableAttributedString(
                    string: content,
                    attributes: [.font: UIFont.footnote,
                                 .foregroundColor: UIColor.secondaryLabel,
                                 .paragraphStyle: paragraph]
                )

                mutableAttributedText.setAsLink(textToFind: Localization.termsOfService,
                                                linkURL: Strings.jetpackTermsURL + self.siteURL)
                mutableAttributedText.setAsLink(textToFind: Localization.shareDetails,
                                                linkURL: Strings.jetpackShareDetailsURL + self.siteURL)
                return mutableAttributedText
            }
            .assign(to: &$termsAttributedString)
    }

    /// Fetches the site info and show the primary button if the site is self-hosted.
    /// If the site is self-hosted, make the Connect Jetpack button visible.
    ///
    func fetchSiteInfo() {
        primaryButtonLoading = true
        authenticatorType.fetchSiteInfo(for: siteURL) { [weak self] result in
            guard let self = self else { return }
            self.primaryButtonLoading = false

            switch result {
            case .success(let siteInfo):
                self.isSelfHostedSite = !siteInfo.isWPCom
            case .failure(let error):
                DDLogWarn("⚠️ Error fetching site info: \(error)")
            }
        }
    }

    func showSiteCredentialLoginAndJetpackConnection(from viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else {
            return
        }
        let coordinator = LoginJetpackSetupCoordinator(siteURL: siteURL,
                                                       connectionOnly: true,
                                                       navigationController: navigationController)
        self.jetpackSetupCoordinator = coordinator
        coordinator.start()
    }

    func presentConnectToWPComSiteAlert(from viewController: UIViewController) {
        let fancyAlert = FancyAlertViewController.makeConnectAccountToWPComSiteAlert()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        viewController.present(fancyAlert, animated: true)
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
                                                          comment: "Action button to handle connecting the logged-in account to a given site."
                                                          + "Presented when logging in with a store address that does not match the account entered")

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

        static let helpBarButtonItemTitle = NSLocalizedString("Help",
                                                       comment: "Help button on account mismatch error screen.")
        static let termsContent = NSLocalizedString(
            "By tapping the Connect Jetpack button, you agree to our %1$@ and to %2$@ with WordPress.com.",
            comment: "Content of the label at the end of the Wrong Account screen. " +
            "Reads like: By tapping the Connect Jetpack button, you agree to our Terms of Service and to share details with WordPress.com.")
        static let termsOfService = NSLocalizedString(
            "Terms of Service",
            comment: "The terms to be agreed upon when tapping the Connect Jetpack button on the Wrong Account screen."
        )
        static let shareDetails = NSLocalizedString(
            "share details",
            comment: "The action to be agreed upon when tapping the Connect Jetpack button on the Wrong Account screen."
        )
    }

    enum Strings {
        static let jetpackTermsURL = "https://jetpack.com/redirect/?source=wpcom-tos&site="
        static let jetpackShareDetailsURL = "https://jetpack.com/redirect/?source=jetpack-support-what-data-does-jetpack-sync&site="
    }
}
