import Foundation
import AuthenticationServices
import WordPressKit

#if XCODE11

@objc protocol AppleAuthenticatorDelegate {
    func showWPComLogin(loginFields: LoginFields)
}

class AppleAuthenticator: NSObject {

    // MARK: - Properties

    static var sharedInstance: AppleAuthenticator = AppleAuthenticator()
    private override init() {}
    private var showFromViewController: UIViewController?
    private let loginFields = LoginFields()
    weak var delegate: AppleAuthenticatorDelegate?

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
            let token = String(data: identityToken, encoding: .utf8),
            let email = appleCredentials.email else {
                DDLogError("Apple Authenticator: invalid Apple credentials.")
                return
        }
        
        let name = fullName(from: appleCredentials.fullName)

        updateLoginFields(email: email, fullName: name, token: token)
        
        let service = SignupService()
        service.createWPComUserWithApple(token: token, email: email, fullName: name,
                                         success: { [weak self] accountCreated, wpcomUsername, wpcomToken in

                                            let wpcom = WordPressComCredentials(authToken: wpcomToken, isJetpackLogin: false, multifactor: false, siteURL: self?.loginFields.siteAddress ?? "")
                                            let credentials = AuthenticatorCredentials(wpcom: wpcom)

                                            // New WP Account
                                            if accountCreated {
                                                self?.authenticationDelegate.createdWordPressComAccount(username: wpcomUsername, authToken: wpcomToken)
                                                self?.signupSuccessful(with: credentials)
                                                return
                                            }

                                            // Existing WP Account
                                            self?.logInInstead()
                                            
            }, failure: { [weak self] error in
                self?.signupFailed(with: error)
        })
    }

    func signupSuccessful(with credentials: AuthenticatorCredentials) {
        WordPressAuthenticator.track(.createdAccount, properties: ["source": "apple"])
        WordPressAuthenticator.track(.signupSocialSuccess)
        showSignupEpilogue(for: credentials)
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
    
    func signupFailed(with error: Error) {
        WPAnalytics.track(.signupSocialFailure)
        DDLogError("Apple Authenticator: signup failed. error: \(error)")
    }
    
    func logInInstead() {
        WordPressAuthenticator.track(.signupSocialToLogin)
        WordPressAuthenticator.track(.loginSocialSuccess)
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
        loginFields.emailAddress = email
        loginFields.username = email
        loginFields.meta.socialServiceIDToken = token
        loginFields.meta.appleUser = AppleUser(email: email, fullName: fullName)
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
        DDLogError("Apple Authenticator: didCompleteWithError: \(error)")
    }

}

@available(iOS 13.0, *)
extension AppleAuthenticator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return showFromViewController?.view.window ?? UIWindow()
    }
}

#endif
