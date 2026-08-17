@testable import WordPressAuthenticator

class WordPressAuthenticatorDelegateSpy: WordPressAuthenticatorDelegate {
    var dismissActionEnabled: Bool = true
    var supportActionEnabled: Bool = true
    var wpcomTermsOfServiceEnabled: Bool = true
    var showSupportNotificationIndicator: Bool = true
    var supportEnabled: Bool = true
    var allowWPComLogin: Bool = true
    var shouldHandleError: Bool = false

    private(set) var presentSignupEpilogueCalled = false
    private(set) var presentLoginEpilogueCalled = false
    private(set) var trackedEvents: [WPAnalyticsStat] = []
    private(set) var lastTrackedProperties: [AnyHashable: Any]?
    private(set) var socialUser: SocialUser?
    var siteCredentialCredentialsToReturn: WordPressOrgCredentials?
    var siteCredentialRecoveries = [SiteCredentialRecovery]()
    var defersSiteCredentialAuthentication = false
    private(set) var siteCredentialAuthenticationRequests = [SiteCredentialAuthenticationRequest]()
    private(set) var siteCredentialAuthenticationLoadingHandler: ((Bool) -> Void)?
    var siteCredentialFailure: (error: Error, incorrectCredentials: Bool, verifiedLoginURL: String?)?
    private(set) var presentedSiteCredentialFailureCount = 0
    private(set) var presentedSiteCredentialFailureOffersBrowserAlternative: Bool?
    private(set) var presentedSiteCredentialBrowserAlternativeCount = 0

    func createdWordPressComAccount(username: String, authToken: String) {
        // no-op
    }

    func userAuthenticatedWithAppleUserID(_ appleUserID: String) {
        // no-op
    }

    func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
        // no-op
    }

    func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (WordPressAuthenticatorResult) -> Void) {
        // no-op
    }

    func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, source: SignInSource?, onDismiss: @escaping () -> Void) {
        presentLoginEpilogueCalled = true
    }

    func presentSignupEpilogue(
        in navigationController: UINavigationController,
        for credentials: AuthenticatorCredentials,
        socialUser: SocialUser?
    ) {
        presentSignupEpilogueCalled = true
        self.socialUser = socialUser
    }

    func presentSupport(from sourceViewController: UIViewController,
                        sourceTag: WordPressSupportSourceTag,
                        lastStep: AuthenticatorAnalyticsTracker.Step,
                        lastFlow: AuthenticatorAnalyticsTracker.Flow,
                        siteURL: String?) {
        // no-op
    }

    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        true
    }

    func shouldHandleError(_ error: Error) -> Bool {
        shouldHandleError
    }

    func handleError(_ error: Error, onCompletion: @escaping (UIViewController) -> Void) {
        if shouldHandleError {
            onCompletion(UIViewController())
        }
    }

    func shouldPresentSignupEpilogue() -> Bool {
        true
    }

    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
        // no-op
    }

    func handleSiteInfoFailure(siteURL: String, error: Error, completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    func authenticateSiteCredentials(credentials: WordPressOrgCredentials,
                                     loginURL: String?,
                                     adminURL: String?,
                                     endpointUnderVerification: SiteCredentialRecoveryEndpoint?,
                                     onLoading: @escaping (Bool) -> Void,
                                     onSuccess: @escaping (WordPressOrgCredentials) -> Void,
                                     onRecovery: @escaping (SiteCredentialRecovery) -> Void,
                                     onFailure: @escaping (Error, Bool, String?) -> Void) {
        siteCredentialAuthenticationRequests.append(.init(
            credentials: credentials,
            loginURL: loginURL,
            adminURL: adminURL,
            endpointUnderVerification: endpointUnderVerification
        ))
        siteCredentialAuthenticationLoadingHandler = onLoading
        onLoading(true)
        guard defersSiteCredentialAuthentication == false else {
            return
        }
        onLoading(false)
        if let failure = siteCredentialFailure {
            siteCredentialFailure = nil
            onFailure(failure.error, failure.incorrectCredentials, failure.verifiedLoginURL)
        } else if siteCredentialRecoveries.isEmpty {
            onSuccess(siteCredentialCredentialsToReturn ?? credentials)
        } else {
            onRecovery(siteCredentialRecoveries.removeFirst())
        }
    }

    func presentSiteCredentialLoginFailure(error: Error,
                                           offersBrowserAlternative: Bool,
                                           for siteURL: String,
                                           in viewController: UIViewController) {
        presentedSiteCredentialFailureCount += 1
        presentedSiteCredentialFailureOffersBrowserAlternative = offersBrowserAlternative
    }

    func presentSiteCredentialBrowserAlternative(for siteURL: String, in viewController: UIViewController) {
        presentedSiteCredentialBrowserAlternativeCount += 1
    }

    func track(event: WPAnalyticsStat) {
        trackedEvents.append(event)
    }

    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        trackedEvents.append(event)
        lastTrackedProperties = properties
    }

    func track(event: WPAnalyticsStat, error: Error) {
        trackedEvents.append(event)
    }
}

struct SiteCredentialAuthenticationRequest {
    let credentials: WordPressOrgCredentials
    let loginURL: String?
    let adminURL: String?
    let endpointUnderVerification: SiteCredentialRecoveryEndpoint?
}
