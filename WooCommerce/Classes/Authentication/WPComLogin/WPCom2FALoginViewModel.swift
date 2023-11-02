import Foundation
import WordPressAuthenticator
import class Networking.UserAgent

/// View model for `WPCom2FALoginView`.
final class WPCom2FALoginViewModel: NSObject, ObservableObject {
    @Published var verificationCode: String = ""
    @Published private(set) var isLoggingIn = false
    @Published private(set) var isRequestingOTP = false

    /// In case the code is entered by pasting from the clipboard, we need to remove all white spaces.
    /// kept non-private for testing purposes.
    var strippedCode: String {
        verificationCode.components(separatedBy: .whitespacesAndNewlines).joined()
    }

    var isValidCode: Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let resultCharacterSet = CharacterSet(charactersIn: strippedCode)
        let isOnlyNumbers = allowedCharacters.isSuperset(of: resultCharacterSet)
        let isValidLength = strippedCode.count <= Constants.maximumCodeLength && strippedCode.isNotEmpty

        if isOnlyNumbers && isValidLength {
            return true
        }
        return false
    }

    private let loginFields: LoginFields
    private let loginFacade: LoginFacade
    private let onLoginFailure: (Error) -> Void
    private let onLoginSuccess: (String) async -> Void

    init(loginFields: LoginFields,
         onLoginFailure: @escaping (Error) -> Void,
         onLoginSuccess: @escaping (String) async -> Void) {
        self.loginFields = loginFields
        self.loginFacade = LoginFacade(dotcomClientID: ApiCredentials.dotcomAppId,
                                       dotcomSecret: ApiCredentials.dotcomSecret,
                                       userAgent: UserAgent.defaultUserAgent)
        self.onLoginFailure = onLoginFailure
        self.onLoginSuccess = onLoginSuccess
        super.init()
        loginFacade.delegate = self
    }

    func handleLogin() {
        isLoggingIn = true
        loginFields.multifactorCode = strippedCode
        loginFacade.signIn(with: loginFields)
    }

    func requestOneTimeCode() {
        isRequestingOTP = true
        loginFacade.wordpressComOAuthClientFacade.requestOneTimeCode(
            withUsername: loginFields.username,
            password: loginFields.password,
            success: { [weak self] in
                self?.isRequestingOTP = false
            }) { [weak self] _ in
                // Errors for this case doesn't need to be handled: pe5sF9-1er-p2
                self?.isRequestingOTP = false
            }
    }
}

extension WPCom2FALoginViewModel: LoginFacadeDelegate {

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

extension WPCom2FALoginViewModel {
    enum Constants {
        // Following the implementation in WordPressAuthenticator
        // swiftlint:disable line_length
        // https://github.com/wordpress-mobile/WordPressAuthenticator-iOS/blob/c0d16065c5b5a8e54dbb54cc31c7b3cf28f584f9/WordPressAuthenticator/Signin/Login2FAViewController.swift#L218
        // swiftlint:enable line_length
        static let maximumCodeLength = 8
    }
}
