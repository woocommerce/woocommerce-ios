import Foundation
import WordPressAuthenticator
import class Networking.UserAgent

/// View model for `WPComPasswordLoginView`.
///
final class WPComPasswordLoginViewModel: NSObject, ObservableObject {

    /// Entered password
    @Published var password: String = ""
    @Published private(set) var isLoggingIn = false

    /// Email address of the WPCom account
    let email: String

    private let siteURL: String
    private let loginFacade: LoginFacade
    private let onMagicLinkRequest: (String) async -> Void
    private let onMultifactorCodeRequest: (LoginFields) -> Void
    private let onLoginFailure: (Error) -> Void
    private let onLoginSuccess: (String) async -> Void

    private(set) var avatarURL: URL?

    init(siteURL: String = "",
         email: String,
         onMagicLinkRequest: @escaping (String) async -> Void,
         onMultifactorCodeRequest: @escaping (LoginFields) -> Void,
         onLoginFailure: @escaping (Error) -> Void,
         onLoginSuccess: @escaping (String) async -> Void) {
        self.siteURL = siteURL
        self.email = email
        self.loginFacade = LoginFacade(dotcomClientID: ApiCredentials.dotcomAppId,
                                       dotcomSecret: ApiCredentials.dotcomSecret,
                                       userAgent: UserAgent.defaultUserAgent)
        self.onMagicLinkRequest = onMagicLinkRequest
        self.onMultifactorCodeRequest = onMultifactorCodeRequest
        self.onLoginFailure = onLoginFailure
        self.onLoginSuccess = onLoginSuccess
        super.init()
        loginFacade.delegate = self
        avatarURL = gravatarUrl(of: email)
    }

    func resetPassword() {
        let loginFields = createLoginFields()
        WordPressAuthenticator.openForgotPasswordURL(loginFields)
    }

    func handleLogin() {
        isLoggingIn = true
        let loginFields = createLoginFields()
        loginFacade.signIn(with: loginFields)
    }

    @MainActor
    func requestMagicLink() async {
        await onMagicLinkRequest(email)
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
            .sha256Hash()
    }

    func createLoginFields(with nonceInfo: SocialLogin2FANonceInfo? = nil, userID: Int = 0) -> LoginFields {
        let loginFields = LoginFields()
        loginFields.username = email
        loginFields.password = password
        loginFields.siteAddress = siteURL
        loginFields.userIsDotCom = true
        loginFields.nonceInfo = nonceInfo
        loginFields.nonceUserID = userID
        return loginFields
    }
}

extension WPComPasswordLoginViewModel: LoginFacadeDelegate {
    func needsMultifactorCode() {
        isLoggingIn = false
        let loginFields = createLoginFields()
        onMultifactorCodeRequest(loginFields)
    }

    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        isLoggingIn = false
        let loginFields = createLoginFields(with: nonceInfo, userID: userID)
        onMultifactorCodeRequest(loginFields)
    }

    func displayRemoteError(_ error: Error) {
        isLoggingIn = false
        onLoginFailure(error)
    }

    func finishedLogin(withAuthToken authToken: String, requiredMultifactorCode: Bool) {
        Task { @MainActor in
            await onLoginSuccess(authToken)
            isLoggingIn = false
        }
    }
}

extension WPComPasswordLoginViewModel {
    enum Constants {
        static let imageSize = 80
        static let baseGravatarURL = "https://gravatar.com/avatar"
        static let gravatarRating = "g" // safest rating
        static let gravatarDefaultOption = "mp" // a simple, cartoon-style silhouetted outline of a person
    }
}
