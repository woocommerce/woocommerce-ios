import Foundation
import AuthenticationServices

#if XCODE11

class AppleAuthenticator: NSObject {

    // MARK: - Properties

    static var sharedInstance: AppleAuthenticator = AppleAuthenticator()
    private override init() {}
    private var showFromViewController: UIViewController?

    // MARK: - Start Authentication

    func showFrom(viewController: UIViewController) {
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
            let email = appleCredentials.email else {
                DDLogError("Apple Authenticator: invalid Apple credentials.")
                return
        }
        
        let service = SignupService()
        service.createWPComUserWithApple(token: identityToken.base64EncodedString(),
                                         email: email,
                                         userName: userName(from: appleCredentials.fullName),
                                         success: { [weak self] accountCreated, wpcomUsername, wpcomToken in
                                            NSLog("Apple Authenticator: createWPComUserWithApple success. accountCreated: ", accountCreated)
            }, failure: { [weak self] error in
                DDLogError("Apple Authenticator: createWPComUserWithApple failure. error: \(error)")
        })
    }

    // MARK: - Helpers
    
    func userName(from components: PersonNameComponents?) -> String {
        guard let name = components else {
            return ""
        }
        return PersonNameComponentsFormatter().string(from: name)
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
