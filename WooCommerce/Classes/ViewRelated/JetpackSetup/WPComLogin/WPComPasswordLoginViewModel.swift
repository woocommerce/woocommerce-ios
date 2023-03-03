import Foundation
import WordPressAuthenticator
import class Networking.UserAgent

/// View model for `WPComPasswordLoginView`.
///
final class WPComPasswordLoginViewModel: NSObject, ObservableObject {

    /// Title of the view.
    let titleString: String

    /// Entered password
    @Published var password: String = ""
    @Published private(set) var isLoggingIn = false

    /// Email address of the WPCom account
    let email: String

    private let siteURL: String
    private let loginFacade: LoginFacade
    private let onMultifactorCodeRequest: () -> Void
    private let onLoginFailure: (Error) -> Void
    private let onLoginSuccess: (String) -> Void

    private(set) var avatarURL: URL?

    private var loginFields: LoginFields {
        let loginFields = LoginFields()
        loginFields.username = email
        loginFields.password = password
        loginFields.siteAddress = siteURL
        loginFields.meta.userIsDotCom = true
        return loginFields
    }

    init(siteURL: String,
         email: String,
         requiresConnectionOnly: Bool,
         onMultifactorCodeRequest: @escaping () -> Void,
         onLoginFailure: @escaping (Error) -> Void,
         onLoginSuccess: @escaping (String) -> Void) {
        self.siteURL = siteURL
        self.email = email
        self.titleString = requiresConnectionOnly ? Localization.connectJetpack : Localization.installJetpack
        self.loginFacade = LoginFacade(dotcomClientID: ApiCredentials.dotcomAppId,
                                       dotcomSecret: ApiCredentials.dotcomSecret,
                                       userAgent: UserAgent.defaultUserAgent)
        self.onMultifactorCodeRequest = onMultifactorCodeRequest
        self.onLoginFailure = onLoginFailure
        self.onLoginSuccess = onLoginSuccess
        super.init()
        loginFacade.delegate = self
        avatarURL = gravatarUrl(of: email)
    }

    func resetPassword() {
        WordPressAuthenticator.openForgotPasswordURL(loginFields)
    }

    func handleLogin() {
        isLoggingIn = true
        loginFacade.signIn(with: loginFields)
    }
}

// MARK: - Helpers
private extension WPComPasswordLoginViewModel {
    /// Constructs Gravatar URL from an email.
    /// Ref: https://en.gravatar.com/site/implement/images/
    func gravatarUrl(of email: String) -> URL? {
        let hash = gravatarHash(of: email)
        let targetURL = String(format: "%@/%@?d=%@&s=%d&r=%@",
                               Constants.baseGravatarURL,
                               hash,
                               Constants.gravatarDefaultOption,
                               Constants.imageSize,
                               Constants.gravatarRating)
        return URL(string: targetURL)
    }

    func gravatarHash(of email: String) -> String {
        return email
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .md5Hash()
    }
}

extension WPComPasswordLoginViewModel: LoginFacadeDelegate {
    func needsMultifactorCode() {
        isLoggingIn = false
        onMultifactorCodeRequest()
    }

    func displayRemoteError(_ error: Error) {
        isLoggingIn = false
        onLoginFailure(error)
    }

    func finishedLogin(withAuthToken authToken: String, requiredMultifactorCode: Bool) {
        isLoggingIn = false
        onLoginSuccess(authToken)
    }
}

extension WPComPasswordLoginViewModel {
    enum Constants {
        static let imageSize = 80
        static let baseGravatarURL = "https://gravatar.com/avatar"
        static let gravatarRating = "g" // safest rating
        static let gravatarDefaultOption = "mp" // a simple, cartoon-style silhouetted outline of a person
    }
    enum Localization {
        static let installJetpack = NSLocalizedString(
            "Install Jetpack",
            comment: "Title for the WPCom magic link screen when Jetpack is not installed yet"
        )
        static let connectJetpack = NSLocalizedString(
            "Connect Jetpack",
            comment: "Title for the WPCom magic link screen when Jetpack is not connected yet"
        )
    }
}
