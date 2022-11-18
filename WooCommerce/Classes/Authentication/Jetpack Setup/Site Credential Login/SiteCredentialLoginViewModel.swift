import Foundation
import WordPressAuthenticator
import class Networking.UserAgent

/// View model for `SiteCredentialLoginView`.
///
final class SiteCredentialLoginViewModel: NSObject, ObservableObject {
    let siteURL: String

    @Published var username: String = ""
    @Published var password: String = ""
    @Published private(set) var primaryButtonDisabled = true
    @Published private(set) var isLoggingIn = false
    @Published private(set) var errorMessage = ""
    @Published var shouldShowErrorAlert = false

    private lazy var loginFacade = LoginFacade(dotcomClientID: ApiCredentials.dotcomAppId,
                                               dotcomSecret: ApiCredentials.dotcomSecret,
                                               userAgent: UserAgent.defaultUserAgent)

    init(siteURL: String) {
        self.siteURL = siteURL
        super.init()
        loginFacade.delegate = self
        configurePrimaryButton()
    }

    func handleLogin() {
        let loginFields = LoginFields()
        loginFields.username = username
        loginFields.password = password
        loginFields.siteAddress = siteURL
        loginFields.meta.userIsDotCom = false
        loginFacade.signIn(with: loginFields)
        isLoggingIn = true
    }
}

// MARK: Private helpers
private extension SiteCredentialLoginViewModel {
    func configurePrimaryButton() {
        $username.combineLatest($password)
            .map { $0.isEmpty || $1.isEmpty }
            .assign(to: &$primaryButtonDisabled)
    }
}

// MARK: LoginFacadeDelegate conformance
//
extension SiteCredentialLoginViewModel: LoginFacadeDelegate {
    func displayRemoteError(_ error: Error) {
        isLoggingIn = false

        let err = error as NSError
        let wrongCredentials = err.domain == Constants.xmlrpcErrorDomain && err.code == Constants.invalidCredentialErrorCode
        errorMessage = wrongCredentials ? Localization.wrongCredentials : Localization.genericFailure
        shouldShowErrorAlert = true
    }

    func finishedLogin(withUsername username: String, password: String, xmlrpc: String, options: [AnyHashable: Any] = [:]) {
        // TODO
        isLoggingIn = false
        print("🎉")
    }
}

extension SiteCredentialLoginViewModel {
    enum Localization {
        static let wrongCredentials = NSLocalizedString(
            "It looks like this username/password isn't associated with this site.",
            comment: "An error message shown during login when the username or password is incorrect."
        )
        static let genericFailure = NSLocalizedString("Login failed. Please try again.", comment: "A generic error during site credential login")
    }

    enum Constants {
        static let xmlrpcErrorDomain = "WPXMLRPCFaultError"
        static let invalidCredentialErrorCode = 403
    }
}
