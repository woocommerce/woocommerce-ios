import Foundation
import AuthenticationServices

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
        #if XCODE11
        if #available(iOS 13.0, *) {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self

            controller.presentationContextProvider = self
            controller.performRequests()
            
        }
        #endif
    }

}

#if XCODE11
@available(iOS 13.0, *)
extension AppleAuthenticator: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentials as ASAuthorizationAppleIDCredential:
            NSLog("Apple Authenticator credentials: \(String(describing: credentials.email)), \(String(describing: credentials.fullName))")
        default:
            break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        NSLog("Apple Authenticator didCompleteWithError: \(error)")
    }

}

@available(iOS 13.0, *)
extension AppleAuthenticator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return showFromViewController?.view.window ?? UIWindow()
    }
}
#endif
