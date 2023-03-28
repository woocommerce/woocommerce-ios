@testable import WordPressAuthenticator

class WordPressAuthenticatorDelegateSpy: WordPressAuthenticatorDelegate {
    var dismissActionEnabled: Bool = true
    var supportActionEnabled: Bool = true
    var wpcomTermsOfServiceEnabled: Bool = true
    var showSupportNotificationIndicator: Bool = true
    var supportEnabled: Bool = true
    var allowWPComLogin: Bool = true

    private(set) var presentSignupEpilogueCalled = false
    private(set) var socialService: SocialService?

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
        // no-op
    }

    func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) {
        presentSignupEpilogueCalled = true
        socialService = service
    }

    func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag, lastStep: AuthenticatorAnalyticsTracker.Step, lastFlow: AuthenticatorAnalyticsTracker.Flow) {
        // no-op
    }

    func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
        true
    }

    func shouldHandleError(_ error: Error) -> Bool {
        true
    }

    func handleError(_ error: Error, onCompletion: @escaping (UIViewController) -> Void) {
        // no-op
    }

    func shouldPresentSignupEpilogue() -> Bool {
        true
    }

    func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
        // no-op
    }

    func track(event: WPAnalyticsStat) {
        // no-op
    }

    func track(event: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        // no-op
    }

    func track(event: WPAnalyticsStat, error: Error) {
        // no-op
    }
}
