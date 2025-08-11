import Foundation
import UIKit
import Yosemite
import enum Alamofire.AFError
import enum Networking.NetworkError
import class Networking.AlamofireNetwork
import protocol WooFoundation.Analytics

/// View model for `JetpackSetupView`.
///
final class JetpackSetupViewModel: ObservableObject {
    let siteURL: String
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    @Published private(set) var connectionOnly: Bool

    private let stores: StoresManager
    private let storeNavigationHandler: (_ connectedEmail: String?) -> Void
    private let wpcomCredentials: Credentials?
    private var isPluginActivated = false

    @Published private(set) var setupSteps: [JetpackInstallStep]

    /// Title to be displayed on the Jetpack setup view
    var title: String {
        let step = currentSetupStep ?? .installation
        if setupFailed, let errorTitle = step.errorTitle {
            return errorTitle
        }
        return connectionOnly ? Localization.connectingJetpack : Localization.installingJetpack
    }

    var shouldShowInitialLoadingIndicator: Bool {
        currentSetupStep == nil && setupFailed == false
    }

    var shouldShowSetupSteps: Bool {
        currentSetupStep != nil && setupFailed == false
    }

    var shouldShowGoToStoreButton: Bool {
        currentSetupStep == .done && setupFailed == false
    }

    var tryAgainButtonTitle: String {
        let step = currentSetupStep ?? .installation
        return step.tryAgainButtonTitle ?? ""
    }

    private(set) var jetpackConnectionURL: URL?
    private let siteConnectionURL: URL?

    @Published private(set) var currentSetupStep: JetpackInstallStep?
    @Published private(set) var currentConnectionStep: ConnectionStep?
    @Published var shouldPresentWebView = false
    @Published var jetpackConnectionInterrupted = false

    /// Whether the setup failed. This will be observed by `LoginJetpackSetupView` to present error modal.
    @Published private(set) var setupFailed: Bool = false
    @Published private(set) var setupErrorDetail: SetupErrorDetail?

    private var jetpackConnectedEmail: String?

    /// Error occurred in any install step
    ///
    private var setupError: Error? {
        didSet {
            updateErrorMessage()
        }
    }

    var hasEncounteredPermissionError: Bool {
        setupError?.errorCode == 403
    }

    /// Attributed string for the description text
    lazy private(set) var descriptionAttributedString: NSAttributedString = {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold
        let siteName = siteURL.trimHTTPScheme()

        let attributedString = NSMutableAttributedString(
            string: String(format: Localization.description, siteName),
            attributes: [.font: font,
                         .foregroundColor: UIColor.text.withAlphaComponent(0.8)
                        ]
        )
        let boldSiteAddress = NSAttributedString(string: siteName, attributes: [.font: boldFont, .foregroundColor: UIColor.text])
        attributedString.replaceFirstOccurrence(of: siteName, with: boldSiteAddress)
        return attributedString
    }()

    private let analytics: Analytics
    private let delayBeforeRetry: Double

    init(siteURL: String,
         connectionOnly: Bool,
         wpcomCredentials: Credentials?,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         delayBeforeRetry: Double = Constants.delayBeforeRetry,
         onStoreNavigation: @escaping (String?) -> Void = { _ in}) {
        self.siteURL = siteURL
        self.connectionOnly = connectionOnly
        self.wpcomCredentials = wpcomCredentials
        self.stores = stores
        self.analytics = analytics
        self.setupSteps = connectionOnly ? [.connection, .done] : JetpackInstallStep.allCases
        self.storeNavigationHandler = onStoreNavigation
        self.siteConnectionURL = URL(string: String(format: Constants.jetpackInstallString, siteURL))
        self.delayBeforeRetry = delayBeforeRetry
    }

    func isSetupStepFailed(_ step: JetpackInstallStep) -> Bool {
        guard let currentStep = currentSetupStep else {
            return false
        }
        return step == currentStep && setupFailed
    }

    func isSetupStepInProgress(_ step: JetpackInstallStep) -> Bool {
        guard let currentStep = currentSetupStep else {
            return false
        }
        return step == currentStep && step != .done
    }

    func isSetupStepPending(_ step: JetpackInstallStep) -> Bool {
        guard let currentStep = currentSetupStep else {
            return false
        }
        return step > currentStep
    }

    func startSetup() {
        if connectionOnly {
            checkJetpackConnection(afterConnection: false)
        } else {
            retrieveJetpackPluginDetails()
        }
    }

    func didAuthorizeJetpackConnection() {
        checkJetpackConnection(afterConnection: true)
    }

    func didEncounterErrorDuringConnection(code: Int?) {
        setupFailed = true
        setupErrorDetail = .init(setupErrorMessage: Localization.connectionErrorMessage,
                                 setupErrorSuggestion: Localization.connectionErrorSuggestion,
                                 errorCode: code)
    }

    func navigateToStore() {
        trackSetupDuringLogin(.loginJetpackSetupGoToStoreTapped)
        trackSetupAfterLogin(tap: .goToStore)
        storeNavigationHandler(jetpackConnectedEmail)
    }

    func retryAllSteps() {
        trackSetupDuringLogin(.loginJetpackSetupScreenTryAgainButtonTapped,
                              properties: currentSetupStep?.analyticsDescription)
        trackSetupAfterLogin(tap: .retry)

        setupFailed = false
        setupError = nil
        setupErrorDetail = nil

        currentSetupStep = nil
        currentConnectionStep = nil
        startSetup()
    }

    /// LoginJetpackSetupInterruptedView
    func didTapContinueConnectionButton() {
        trackSetupDuringLogin(.loginJetpackSetupScreenTryAgainButtonTapped)
        trackSetupAfterLogin(tap: .continueSetup)
        checkJetpackConnection(afterConnection: false)
    }

    /// Tracks events if the current flow is Jetpack setup during login
    func trackSetupDuringLogin(_ stat: WooAnalyticsStat,
                               properties: [AnyHashable: Any]? = nil,
                               failure: Error? = nil) {
        guard stores.isAuthenticated == false else {
            return
        }
        analytics.track(stat, properties: properties, error: failure)
    }

    /// Tracks events if the current flow is Jetpack setup after login with site credentials
    func trackSetupAfterLogin(tap: WooAnalyticsEvent.JetpackSetup.SetupFlow.TapTarget? = nil,
                              failure: Error? = nil) {
        guard stores.isAuthenticated else {
            return
        }
        /// Helper for analytics since `currentSetupStep` is optional.
        let currentStepForAnalytics: JetpackInstallStep = currentSetupStep ?? (connectionOnly ? .connection : .installation)
        analytics.track(event: .JetpackSetup.setupFlow(step: currentStepForAnalytics,
                                                       tap: tap,
                                                       failure: failure))
    }
}

// MARK: Private helpers
//
private extension JetpackSetupViewModel {
    func retrieveJetpackPluginDetails() {
        let action = JetpackConnectionAction.retrieveJetpackPluginDetails { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let plugin):
                if plugin.status == .inactive {
                    self.activateJetpack()
                } else {
                    self.checkJetpackConnection(afterConnection: false)
                }
            case .failure(let error):
                DDLogError("⛔️ Error retrieving Jetpack: \(error)")
                self.setupError = error
                if error.errorCode == 404 {
                    if self.connectionOnly {
                        /// If site has Jetpack connection package connected,
                        /// Jetpack plugin needs to be installed even though we detected a connection before
                        self.setupSteps = JetpackInstallStep.allCases
                        self.connectionOnly = false
                    }
                    /// plugin is likely to not have been installed, so proceed to install it.
                    self.installJetpack()
                } else {
                    self.setupFailed = true
                }
            }
        }
        stores.dispatch(action)
    }

    func installJetpack() {
        currentSetupStep = .installation
        trackSetupAfterLogin()

        let action = JetpackConnectionAction.installJetpackPlugin { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.trackSetupDuringLogin(.loginJetpackSetupScreenInstallSuccessful)
                self.activateJetpack()
            case .failure(let error):
                self.trackSetupDuringLogin(.loginJetpackSetupScreenInstallFailed, failure: error)
                self.trackSetupAfterLogin(failure: error)
                DDLogError("⛔️ Error installing Jetpack: \(error)")
                self.setupError = error
                self.setupFailed = true
            }
        }
        stores.dispatch(action)
    }

    func activateJetpack() {
        currentSetupStep = .activation
        trackSetupAfterLogin()
        let action = JetpackConnectionAction.activateJetpackPlugin { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                isPluginActivated = true
                self.trackSetupDuringLogin(.loginJetpackSetupActivationSuccessful)
                self.checkJetpackConnection(afterConnection: false)
            case .failure(let error):
                self.trackSetupDuringLogin(.loginJetpackSetupActivationFailed, failure: error)
                self.trackSetupAfterLogin(failure: error)
                DDLogError("⛔️ Error activating Jetpack: \(error)")
                self.setupError = error
                self.setupFailed = true
            }
        }
        stores.dispatch(action)
    }

    /// Jetpack connection flow using web view.
    /// Used only for sites with Jetpack plugin versions lower than 14.4.
    ///
    func startConnectionWithWebView() {
        currentSetupStep = .connection
        trackSetupAfterLogin()
        let action = JetpackConnectionAction.fetchJetpackConnectionURL { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let url):
                self.trackSetupDuringLogin(.loginJetpackSetupFetchJetpackConnectionURLSuccessful)
                /// Checks if the fetch URL is for account connection;
                /// if not, use the web view solution to avoid the need for cookie-nonce.
                /// Reference: pe5sF9-1le-p2#comment-1942.
                if url.absoluteString.hasPrefix(Constants.accountConnectionURL) {
                    self.jetpackConnectionURL = url
                } else {
                    self.jetpackConnectionURL = self.siteConnectionURL
                }
                self.shouldPresentWebView = true
            case .failure(let error):
                self.trackSetupDuringLogin(.loginJetpackSetupFetchJetpackConnectionURLFailed, failure: error)
                self.trackSetupAfterLogin(failure: error)
                DDLogError("⛔️ Error fetching Jetpack connection URL: \(error)")
                self.setupError = error
                self.setupFailed = true
            }
        }
        stores.dispatch(action)
    }

    func updateErrorMessage() {
        guard let setupErrorCode = setupError?.errorCode else {
            setupErrorDetail = .init(setupErrorMessage: Localization.genericErrorMessage,
                                     setupErrorSuggestion: Localization.communicationErrorSuggestion,
                                     errorCode: nil)
            return
        }

        switch setupErrorCode {
        case 403:
            setupErrorDetail = .init(setupErrorMessage: Localization.permissionErrorMessage,
                                     setupErrorSuggestion: Localization.permissionErrorSuggestion,
                                     errorCode: setupErrorCode)
        case 500...599:
            setupErrorDetail = .init(setupErrorMessage: Localization.communicationErrorMessage,
                                     setupErrorSuggestion: Localization.communicationErrorSuggestion,
                                     errorCode: setupErrorCode)
        default:
            setupErrorDetail = .init(setupErrorMessage: Localization.genericErrorMessage,
                                     setupErrorSuggestion: Localization.communicationErrorSuggestion,
                                     errorCode: setupErrorCode)
        }
    }
}

// MARK: Handle connection steps
// Ref: pe5sF9-401-p2
private extension JetpackSetupViewModel {
    func checkJetpackConnection(afterConnection: Bool, retryCount: Int = 0) {
        currentConnectionStep = .inProgress
        let action = JetpackConnectionAction.fetchJetpackConnectionData { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let connectionData):
                if afterConnection {
                    checkConnectedUser(data: connectionData, retryCount: retryCount)
                } else {
                    handleJetpackConnectionData(connectionData)
                }
            case .failure(let error):
                DDLogError("⛔️ Error checking Jetpack connection: \(error)")
                if retryCount == Constants.maxRetryCount {
                    return didFailJetpackConnection(with: error)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeRetry) { [weak self] in
                    self?.checkJetpackConnection(afterConnection: afterConnection, retryCount: retryCount + 1)
                }
            }
        }
        stores.dispatch(action)
    }

    func checkConnectedUser(data: JetpackConnectionData, retryCount: Int = 0) {
        let connectedEmail = data.currentUser.wpcomUser?.email
        if let connectedEmail {
            return didCompleteJetpackConnection(connectedEmail: connectedEmail)
        }

        DDLogWarn("⚠️ Cannot find connected WPcom user")
        let missingWpcomUserError = NSError(domain: Constants.errorDomain,
                                            code: Constants.errorCodeNoWPComUser,
                                            userInfo: [Constants.errorUserInfoReason: Constants.errorUserInfoNoWPComUser])
        trackSetupDuringLogin(.loginJetpackSetupCannotFindWPCOMUser, failure: missingWpcomUserError)
        if retryCount == Constants.maxRetryCount {
            return didFailJetpackConnection(with: missingWpcomUserError)
        }
        // Retry fetching user in case Jetpack sync takes some time.
        DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforeRetry) { [weak self] in
            self?.checkJetpackConnection(afterConnection: true, retryCount: retryCount + 1)
        }
    }

    func handleJetpackConnectionData(_ data: JetpackConnectionData) {
        if let connectedEmail = data.currentUser.wpcomUser?.email {
            return didCompleteJetpackConnection(connectedEmail: connectedEmail)
        }

        if let isRegistered = data.isRegistered {
            return handleSiteRegisterResult(isRegistered: isRegistered, blogID: data.blogID)
        }

        if isPluginActivated {
            /// Skips plugin check if plugin has just got activated.
            /// `isRegistered` is unavailable due to outdated Jetpack. Proceed with web flow.
            startConnectionWithWebView()
        } else {
            /// Fetch plugin details to check
            stores.dispatch(JetpackConnectionAction.retrieveJetpackPluginDetails { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    /// Plugin is available but`isRegistered` is unavailable due to outdated version.
                    /// Proceed with web flow.
                    startConnectionWithWebView()
                case .failure(let error):
                    if error.errorCode == 404 {
                        /// For Jetpack-connected sites, if `isRegistered` is not returned,
                        /// check for `connectionOwner` instead.
                        handleSiteRegisterResult(isRegistered: data.connectionOwner != nil, blogID: data.blogID)
                    } else {
                        didFailJetpackConnection(with: error)
                    }
                }
            })
        }
    }

    func handleSiteRegisterResult(isRegistered: Bool, blogID: Int64?) {
        if let blogID, isRegistered {
            provisionSiteConnection(blogID: blogID)
        } else {
            registerSiteConnection()
        }
    }

    func registerSiteConnection() {
        stores.dispatch(JetpackConnectionAction.registerSite(completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let blogID):
                provisionSiteConnection(blogID: blogID)
            case .failure(let error):
                didFailJetpackConnection(with: error)
            }
        }))
    }

    func provisionSiteConnection(blogID: Int64) {
        currentSetupStep = .connection
        trackSetupAfterLogin()
        stores.dispatch(JetpackConnectionAction.provisionConnection(completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                finalizeSiteConnection(blogID: blogID, provisionResponse: response)
            case .failure(let error):
                didFailJetpackConnection(with: error)
            }
        }))
    }

    func finalizeSiteConnection(blogID: Int64, provisionResponse: JetpackConnectionProvisionResponse) {
        guard let wpcomCredentials, case .wpcom = wpcomCredentials else {
            /// WPCom credentials are necessary to finalize connection through API
            /// If this is unavailable, fall back to the web flow.
            return startConnectionWithWebView()
        }
        let network = AlamofireNetwork(credentials: wpcomCredentials)
        stores.dispatch(JetpackConnectionAction.finalizeConnection(
            siteID: blogID,
            siteURL: siteURL,
            provisionResponse: provisionResponse,
            network: network
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                checkJetpackConnection(afterConnection: true)
            case .failure(let error):
                didFailJetpackConnection(with: error)
            }
        })
    }

    func didCompleteJetpackConnection(connectedEmail: String) {
        jetpackConnectedEmail = connectedEmail
        currentConnectionStep = .authorized
        currentSetupStep = .done

        trackSetupDuringLogin(.loginJetpackSetupAllStepsMarkedDone)
        trackSetupAfterLogin()
    }

    func didFailJetpackConnection(with error: Error) {
        setupFailed = true
        setupError = error
        if let setupError {
            analytics.track(.loginJetpackSetupErrorCheckingJetpackConnection, withError: setupError)
        }
    }
}

// MARK: Subtypes
//
extension JetpackSetupViewModel {
    /// Details for setup error to display on `LoginJetpackSetupView`
    ///
    struct SetupErrorDetail: Equatable {
        let setupErrorMessage: String
        let setupErrorSuggestion: String
        let errorCode: Int?
    }

    /// Steps for the Jetpack connection process.
    ///
    enum ConnectionStep {
        case inProgress
        case authorized

        var title: String {
            switch self {
            case .inProgress:
                return JetpackSetupViewModel.Localization.validating
            case .authorized:
                return JetpackSetupViewModel.Localization.connectionApproved
            }
        }

        var tintColor: UIColor {
            switch self {
            case .inProgress:
                return .secondaryLabel
            case .authorized:
                return .withColorStudio(.green, shade: .shade50)
            }
        }
    }

    enum Localization {
        static let installingJetpack = NSLocalizedString(
            "Installing Jetpack",
            comment: "Title for the Jetpack setup screen when installation is required"
        )
        static let connectingJetpack = NSLocalizedString(
            "Connecting Jetpack",
            comment: "Title for the Jetpack setup screen when connection is required"
        )
        static let description = NSLocalizedString(
            "Please wait while we connect your store %1$@ with Jetpack.",
            comment: "Message on the Jetpack setup screen. The %1$@ is the site address."
        )
        static let validating = NSLocalizedString(
            "Validating",
            comment: "Message to be displayed when a Jetpack connection is being authorized"
        )
        static let connectionApproved = NSLocalizedString(
            "Connected",
            comment: "Message to be displayed when a Jetpack connection has been authorized"
        )
        static let permissionErrorMessage = NSLocalizedString(
            "You don't have permission to manage plugins on this store.",
            comment: "Message to be displayed when the user encounters a permission error during Jetpack setup"
        )
        static let permissionErrorSuggestion = NSLocalizedString(
            "Please contact your shop manager or administrator for help.",
            comment: "Suggestion to be displayed when the user encounters a permission error during Jetpack setup"
        )
        static let communicationErrorMessage = NSLocalizedString(
            "There was an error communicating with your site.",
            comment: "Message to be displayed when there's an error communicating with the remote site during Jetpack setup"
        )
        static let communicationErrorSuggestion = NSLocalizedString(
            "Please try again or contact support if this error continues.",
            comment: "Suggestion to be displayed when there's an error communicating with the remote site during Jetpack setup"
        )
        static let genericErrorMessage = NSLocalizedString(
            "There was an error completing your request.",
            comment: "Message to be displayed when the user encounters a generic error during Jetpack setup"
        )
        static let connectionErrorMessage = NSLocalizedString(
            "There was an error connecting your site to Jetpack.",
            comment: "Message to be displayed when the user encounters an error during the connection step of Jetpack setup"
        )
        static let connectionErrorSuggestion = NSLocalizedString(
            "Please connect Jetpack through your admin page on a browser or contact support.",
            comment: "Suggestion to be displayed when the user encounters an error during the connection step of Jetpack setup"
        )
    }

    private enum Constants {
        static let maxRetryCount: Int = 2
        static let delayBeforeRetry: Double = 0.5
        static let errorDomain = "LoginJetpackSetup"
        static let errorCodeNoWPComUser = 99
        static let errorUserInfoReason = "reason"
        static let errorUserInfoNoWPComUser = "No connected WP.com user found"
        static let jetpackInstallString = "%@/wp-admin/admin.php?page=jetpack"
        static let accountConnectionURL = "https://jetpack.wordpress.com/jetpack.authorize"
    }
}

fileprivate extension Error {
    var errorCode: Int? {
        if let error = self as? NetworkError, let code = error.responseCode {
            return code
        } else if let error = self as? AFError, let code = error.responseCode {
            return code
        } else {
            return (self as NSError).code
        }
    }
}
