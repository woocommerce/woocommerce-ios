@testable import WordPressAuthenticator

class WordPressAuthenticatorDelegateSpy: WordPressAuthenticatorDelegate {
var dismissActionEnabled: Bool

var supportActionEnabled: Bool

var showSupportNotificationIndicator: Bool

var supportEnabled: Bool

var allowWPComLogin: Bool

var trackedElement: WPAnalyticsStat?

init() {
    self.dismissActionEnabled = false
    self.supportActionEnabled = false
    self.showSupportNotificationIndicator = false
    self.supportEnabled = false
    self.allowWPComLogin = false
    self.trackedElement = nil
}

func createdWordPressComAccount(username: String, authToken: String) {
    //Implement later
}

func userAuthenticatedWithAppleUserID(_ appleUserID: String) {
    //Implement Later
}

func presentSupportRequest(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
    //Implement Later
}

func shouldPresentUsernamePasswordController(for siteInfo: WordPressComSiteInfo?, onCompletion: @escaping (Error?, Bool) -> Void) {
    //Implement Later
}

func presentLoginEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, onDismiss: @escaping () -> Void) {
    //Implement Later
}

func presentSignupEpilogue(in navigationController: UINavigationController, for credentials: AuthenticatorCredentials, service: SocialService?) {
    //Implement Later
}

func presentSupport(from sourceViewController: UIViewController, sourceTag: WordPressSupportSourceTag) {
    //Implement Later
}

func shouldPresentLoginEpilogue(isJetpackLogin: Bool) -> Bool {
    //Implement Later
    return isJetpackLogin
}

func shouldPresentSignupEpilogue() -> Bool {
    //Implement Later
    return false
}

func sync(credentials: AuthenticatorCredentials, onCompletion: @escaping () -> Void) {
    //Implement Later
}

func track(event: WPAnalyticsStat) {
    trackedElement = event
}

func track(event: WPAnalyticsStat, properties: [AnyHashable : Any]) {
    //Implement Later
}

func track(event: WPAnalyticsStat, error: Error) {
    //Implement Later
}

}

