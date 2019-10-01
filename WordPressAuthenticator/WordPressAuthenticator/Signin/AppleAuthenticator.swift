import Foundation
import AuthenticationServices
import WordPressKit
import SVProgressHUD

@objc protocol AppleAuthenticatorDelegate {
    func showWPComLogin(loginFields: LoginFields)
    func authFailedWithError(message: String)
}

class AppleAuthenticator: NSObject {

    // MARK: - Properties

    static var sharedInstance: AppleAuthenticator = AppleAuthenticator()
    private override init() {}
    private var showFromViewController: UIViewController?
    private let loginFields = LoginFields()
    weak var delegate: AppleAuthenticatorDelegate?
    
    @available(iOS 13.0, *)
    static let credentialRevokedNotification = ASAuthorizationAppleIDProvider.credentialRevokedNotification

    private var authenticationDelegate: WordPressAuthenticatorDelegate {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }
        return delegate
    }
    
    // MARK: - Start Authentication

    func showFrom(viewController: UIViewController) {
        loginFields.meta.socialService = SocialServiceName.apple
        showFromViewController = viewController
        requestAuthorization()
    }

}

private extension AppleAuthenticator {

    func requestAuthorization() {
        if #available(iOS 13.0, *) {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self

            controller.presentationContextProvider = self
            controller.performRequests()
            
        }
    }

    /// Creates a WordPress.com account with the Apple ID
    ///
    @available(iOS 13.0, *)
    func createWordPressComUser(appleCredentials: ASAuthorizationAppleIDCredential) {
        guard let identityToken = appleCredentials.identityToken,
            let token = String(data: identityToken, encoding: .utf8) else {
                DDLogError("Apple Authenticator: invalid Apple credentials.")
                return
        }
        
        SVProgressHUD.show(withStatus: NSLocalizedString("Continuing with Apple", comment: "Shown while logging in with Apple and the app waits for the site creation process to complete."))
        
        let email = appleCredentials.email ?? ""
        let name = fullName(from: appleCredentials.fullName)

        updateLoginFields(email: email, fullName: name, token: token)
        
        let service = SignupService()
        service.createWPComUserWithApple(token: token, email: email, fullName: name,
                                         success: { [weak self] accountCreated, existingNonSocialAccount, wpcomUsername, wpcomToken in
                                            SVProgressHUD.dismiss()

                                            // Notify host app of successful Apple authentication
                                            self?.authenticationDelegate.userAuthenticatedWithAppleUserID(appleCredentials.user)
                                            
                                            guard !existingNonSocialAccount else {
                                                self?.updateLoginEmail(wpcomUsername)
                                                self?.logInInstead()
                                                return
                                            }

                                            let wpcom = WordPressComCredentials(authToken: wpcomToken, isJetpackLogin: false, multifactor: false, siteURL: self?.loginFields.siteAddress ?? "")
                                            let credentials = AuthenticatorCredentials(wpcom: wpcom)

                                            if accountCreated {
                                                self?.authenticationDelegate.createdWordPressComAccount(username: wpcomUsername, authToken: wpcomToken)
                                                self?.signupSuccessful(with: credentials)
                                            } else {
                                                self?.authenticationDelegate.sync(credentials: credentials) {
                                                    self?.loginSuccessful(with: credentials)
                                                }
                                            }

            }, failure: { [weak self] error in
                SVProgressHUD.dismiss()
                self?.signupFailed(with: error)
        })
    }

    func signupSuccessful(with credentials: AuthenticatorCredentials) {
        WordPressAuthenticator.track(.createdAccount, properties: ["source": "apple"])
        WordPressAuthenticator.track(.signupSocialSuccess, properties: ["source": "apple"])
        showSignupEpilogue(for: credentials)
    }
    
    func loginSuccessful(with credentials: AuthenticatorCredentials) {
        WordPressAuthenticator.track(.signedIn, properties: ["source": "apple"])
        WordPressAuthenticator.track(.loginSocialSuccess, properties: ["source": "apple"])
        showLoginEpilogue(for: credentials)
    }
    
    func showSignupEpilogue(for credentials: AuthenticatorCredentials) {
        guard let navigationController = showFromViewController?.navigationController else {
            fatalError()
        }

        let service = loginFields.meta.appleUser.flatMap {
            return SocialService.apple(user: $0)
        }

        authenticationDelegate.presentSignupEpilogue(in: navigationController, for: credentials, service: service)
    }
    
    func showLoginEpilogue(for credentials: AuthenticatorCredentials) {
        guard let navigationController = showFromViewController?.navigationController else {
            fatalError()
        }

        authenticationDelegate.presentLoginEpilogue(in: navigationController, for: credentials) {}
    }
    
    func signupFailed(with error: Error) {
        DDLogError("Apple Authenticator: Signup failed. error: \(error.localizedDescription)")
        WordPressAuthenticator.track(.signupSocialFailure, properties: ["source": "apple"])
        delegate?.authFailedWithError(message: error.localizedDescription)
    }
    
    func logInInstead() {
        WordPressAuthenticator.track(.signupSocialToLogin, properties: ["source": "apple"])
        WordPressAuthenticator.track(.loginSocialSuccess, properties: ["source": "apple"])
        delegate?.showWPComLogin(loginFields: loginFields)
    }
    
    // MARK: - Helpers
    
    func fullName(from components: PersonNameComponents?) -> String {
        guard let name = components else {
            return ""
        }
        return PersonNameComponentsFormatter().string(from: name)
    }
    
    func updateLoginFields(email: String, fullName: String, token: String) {
        updateLoginEmail(email)
        loginFields.meta.socialServiceIDToken = token
        loginFields.meta.appleUser = AppleUser(email: email, fullName: fullName)
    }

    func updateLoginEmail(_ email: String) {
        loginFields.emailAddress = email
        loginFields.username = email
    }

}

@available(iOS 13.0, *)
extension AppleAuthenticator: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            createWordPressComUser(appleCredentials: credentials)
        default:
            break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {

        // Don't show error if user cancelled authentication.
        if let authorizationError = error as? ASAuthorizationError,
        authorizationError.code == .canceled {
            return
        }
        
        DDLogError("Apple Authenticator: didCompleteWithError: \(error.localizedDescription)")
        let message = NSLocalizedString("Apple authentication failed.", comment: "Message shown when Apple authentication fails.")
        delegate?.authFailedWithError(message: message)
    }

}

@available(iOS 13.0, *)
extension AppleAuthenticator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return showFromViewController?.view.window ?? UIWindow()
    }
}

@available(iOS 13.0, *)
extension AppleAuthenticator {
    func getAppleIDCredentialState(for userID: String,
                                   completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState, Error?) -> Void) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID, completion: completion)
    }
}
