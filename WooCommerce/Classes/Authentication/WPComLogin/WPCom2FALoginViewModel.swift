import AuthenticationServices
import Foundation
import enum WordPressKit.WordPressComOAuthError
import WordPressAuthenticator
import class Networking.UserAgent

/// View model for `WPCom2FALoginView`.
final class WPCom2FALoginViewModel: NSObject, ObservableObject {
    @Published var verificationCode: String = ""
    @Published private(set) var isLoggingIn = false
    @Published private(set) var isRequestingOTP = false

    var shouldEnableSecurityKeyOption: Bool {
        loginFields.nonceInfo?.nonceWebauthn != nil
    }

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

    /// Tracks when the initial challenge request was made.
    private var initialChallengeRequestTime: Date?

    private let loginFields: LoginFields
    private let loginFacade: LoginFacade
    private let onAuthWindowRequest: () -> UIWindow
    private let onLoginFailure: (TwoFALoginError) -> Void
    private let onLoginSuccess: (String) async -> Void

    init(loginFields: LoginFields,
         onAuthWindowRequest: @escaping () -> UIWindow,
         onLoginFailure: @escaping (TwoFALoginError) -> Void,
         onLoginSuccess: @escaping (String) async -> Void) {
        self.loginFields = loginFields
        self.loginFacade = LoginFacade(dotcomClientID: ApiCredentials.dotcomAppId,
                                       dotcomSecret: ApiCredentials.dotcomSecret,
                                       userAgent: UserAgent.defaultUserAgent)
        self.onAuthWindowRequest = onAuthWindowRequest
        self.onLoginFailure = onLoginFailure
        self.onLoginSuccess = onLoginSuccess
        super.init()
        loginFacade.delegate = self
    }

    @available(iOS 16, *)
    func loginWithSecurityKey() {
        guard let twoStepNonce = loginFields.nonceInfo?.nonceWebauthn else {
            return handleError(.webAuthNonceNotFound)
        }

        isLoggingIn = true
        initialChallengeRequestTime = Date()

        Task { @MainActor in
            guard let challengeInfo = await loginFacade.requestWebauthnChallenge(userID: loginFields.nonceUserID, twoStepNonce: twoStepNonce) else {
                return handleError(.webAuthChallengeRequestFailed)
            }

            signChallenge(challengeInfo)
        }
    }

    func handleLogin() {
        isLoggingIn = true
        if let nonceInfo = loginFields.nonceInfo {
            let (authType, nonce) = nonceInfo.authTypeAndNonce(for: strippedCode)
            guard nonce.isNotEmpty else {
                return handleError(.bad2FACode)
            }
            loginFacade.loginToWordPressDotCom(withUser: loginFields.nonceUserID, authType: authType, twoStepCode: strippedCode, twoStepNonce: nonce)
        } else {
            loginFields.multifactorCode = strippedCode
            loginFacade.signIn(with: loginFields)
        }
    }

    func requestOneTimeCode() {
        isRequestingOTP = true
        loginFacade.wordpressComOAuthClientFacade.requestOneTimeCode(
            username: loginFields.username,
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
        let twoFAError = checkFailure(error: error)
        handleError(twoFAError)
    }

    func finishedLogin(withAuthToken authToken: String, requiredMultifactorCode: Bool) {
        Task { @MainActor in
            await onLoginSuccess(authToken)
            isLoggingIn = false
        }
    }

    func finishedLogin(withNonceAuthToken authToken: String) {
        Task { @MainActor in
            await onLoginSuccess(authToken)
            isLoggingIn = false
        }
    }
}

// MARK: - Security Keys
extension WPCom2FALoginViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        // Validate necessary data
        guard #available(iOS 16, *),
              let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion,
              let challengeInfo = loginFields.webauthnChallengeInfo,
              let clientDataJson = extractClientData(from: credential, challengeInfo: challengeInfo) else {
            return handleError(.webAuthChallengeRequestFailed)
        }

        // Validate that the submitted passkey is allowed.
        guard challengeInfo.allowedCredentialIDs.contains(credential.credentialID.base64URLEncodedString()) else {
            return handleError(.invalidSecurityKey)
        }

        loginFacade.authenticateWebauthnSignature(userID: loginFields.nonceUserID,
                                                  twoStepNonce: challengeInfo.twoStepNonce,
                                                  credentialID: credential.credentialID,
                                                  clientDataJson: clientDataJson,
                                                  authenticatorData: credential.rawAuthenticatorData,
                                                  signature: credential.signature,
                                                  userHandle: credential.userID)
    }

    // Some password managers(like 1P) don't deliver `rawClientDataJSON`. In those cases we need to assemble it manually.
    @available(iOS 16, *)
    func extractClientData(from credential: ASAuthorizationPlatformPublicKeyCredentialAssertion, challengeInfo: WebauthnChallengeInfo) -> Data? {

        if credential.rawClientDataJSON.count > 0 {
            return credential.rawClientDataJSON
        }

        // We build this manually because we need to guarantee this exact element order.
        let rawClientJSON = "{\"type\":\"webauthn.get\",\"challenge\":\"\(challengeInfo.challenge)\",\"origin\":\"https://\(challengeInfo.rpID)\"}"
        return rawClientJSON.data(using: .utf8)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DDLogError("⛔️ Error signing challenge: \(error.localizedDescription)")
        handleError(.webAuthChallengeRequestFailed)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        onAuthWindowRequest()
    }
}

// MARK: - Helpers
//
private extension WPCom2FALoginViewModel {
    @available(iOS 16, *)
    func signChallenge(_ challengeInfo: WebauthnChallengeInfo) {

        loginFields.nonceInfo?.updateNonce(with: challengeInfo.twoStepNonce)
        loginFields.webauthnChallengeInfo = challengeInfo

        let challenge = Data(base64URLEncoded: challengeInfo.challenge) ?? Data()
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: challengeInfo.rpID)
        let platformKeyRequest = platformProvider.createCredentialAssertionRequest(challenge: challenge)

        let authController = ASAuthorizationController(authorizationRequests: [platformKeyRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
    }

    /// Matches error with an equivalent `TwoFALoginError`.
    func checkFailure(error: Error) -> TwoFALoginError {
        let nsError = error as NSError

        // If the error happened because the security key challenge request started more than 1 minute ago, show a timeout error.
        // This check is needed because the server sends a generic error.
        if let initialChallengeRequestTime,
            Date().timeIntervalSince(initialChallengeRequestTime) >= 60,
            nsError.code == .zero {
            return .securityKeyChallengeTimeout
        }

        switch error {
        case let WordPressComOAuthError.endpointError(failure) where failure.kind == .invalidOneTimePassword:
            return .bad2FACode
        case let WordPressComOAuthError.endpointError(failure) where failure.kind == .invalidTwoStepCode:
            // Invalid 2FA during social login
            if let newNonce = failure.newNonce {
                loginFields.nonceInfo?.updateNonce(with: newNonce)
            }
            return .bad2FACode
        default:
            return .genericFailure(underlyingError: nsError)
        }
    }

    /// Triggers failure callback with the final error.
    func handleError(_ error: TwoFALoginError) {
        isLoggingIn = false
        onLoginFailure(error)
    }
}

private extension WPCom2FALoginViewModel {
    enum Constants {
        // Following the implementation in WordPressAuthenticator
        // swiftlint:disable line_length
        // https://github.com/wordpress-mobile/WordPressAuthenticator-iOS/blob/c0d16065c5b5a8e54dbb54cc31c7b3cf28f584f9/WordPressAuthenticator/Signin/Login2FAViewController.swift#L218
        // swiftlint:enable line_length
        static let maximumCodeLength = 8
    }
}

enum TwoFALoginError: Error, Equatable {
    case securityKeyChallengeTimeout
    case webAuthNonceNotFound
    case webAuthChallengeRequestFailed
    case invalidSecurityKey
    case bad2FACode
    case genericFailure(underlyingError: NSError)

    var errorMessage: String {
        switch self {
        case .securityKeyChallengeTimeout:
            return Localization.timeoutError
        case .webAuthNonceNotFound, .webAuthChallengeRequestFailed:
            return Localization.unknownError
        case .invalidSecurityKey:
            return Localization.invalidSecurityKey
        case .bad2FACode:
            return Localization.bad2FAError
        case .genericFailure(let error):
            return error.localizedDescription
        }
    }

    enum Localization {
        static let unknownError = NSLocalizedString(
            "wpCom2FALoginViewModel.unknownError",
            value: "Whoops, something went wrong. Please try again!",
            comment: "Generic error on the 2FA login screen"
        )
        static let invalidSecurityKey = NSLocalizedString(
            "wpCom2FALoginViewModel.invalidSecurityKey",
            value: "Whoops, that security key does not seem valid. Please try again with another one",
            comment: "Error when the uses chooses an invalid security key on the 2FA screen."
        )
        static let bad2FAError = NSLocalizedString(
            "wpCom2FALoginViewModel.bad2FA",
            value: "Whoops, that's not a valid two-factor verification code. " +
            "Double-check your code and try again!",
            comment: "Error message shown when an incorrect two factor code is provided."
        )
        static let timeoutError = NSLocalizedString(
            "wpCom2FALoginViewModel.timeoutError",
            value: "Time's up, but don't worry, your security is our priority. Please try again!",
            comment: "Error when the uses takes more than 1 minute to submit a security key."
        )
    }
}
