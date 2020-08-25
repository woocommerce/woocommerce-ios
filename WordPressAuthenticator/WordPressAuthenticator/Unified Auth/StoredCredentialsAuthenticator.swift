import Foundation
import AuthenticationServices

/// This class  implements the logic to present a UI so that our users can quickly log in with credentials stored
/// in their iCloud Keychain, or with their Apple ID if the user has previously used SIWA with the App.
///
@available(iOS 13, *)
class StoredCredentialsAuthenticator: NSObject {
    
    private var authConfig: WordPressAuthenticatorConfiguration {
        WordPressAuthenticator.shared.configuration
    }
    
    private lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade(dotcomClientID: authConfig.wpcomClientId,
                                 dotcomSecret: authConfig.wpcomSecret,
                                 userAgent: authConfig.userAgent)
        facade.delegate = self
        return facade
    }()
    
    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }
    
    private let picker = StoredCredentialsPicker()

    // Showing the UI
    
    func showPicker(in window: UIWindow) {
        picker.show(in: window) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let authorization):
                self.pickerSuccess(authorization)
            case .failure(let error):
                self.pickerFailure(error)
            }
        }
    }
    
    // MARK: - Picker Interactions
    
    /// The selection of credentials and subsequent authorization by the OS succeeded.  This method processes the credentials
    /// and proceeds with the login operation.
    ///
    /// - Parameters:
    ///         - authorization: The authorization by the OS, containing the credentials picked by the user.
    ///
    private func pickerSuccess(_ authorization: ASAuthorization) {
        switch authorization.credential {
        case _ as ASAuthorizationAppleIDCredential:
            // No-op for now, but we can decide to implement AppleID login through this authenticator
            // by implementing the logic here.
            break
        case let credential as ASPasswordCredential:
            tracker.set(flow: .loginWithiCloudKeychain)
            tracker.track(step: .start)
            
            let loginFields = LoginFields.makeForWPCom(username: credential.user, password: credential.password)
            loginFacade.signIn(with: loginFields)
        default:
            // There aren't any other known methods for us to handle here, but we still need to complete the switch
            // statement.
            break
        }
    }
    
    /// The selection of credentials or the subsequent authorization by the OS failed.  This method processes the failure.
    ///
    /// - Parameters:
    ///         - error: The error detailing what failed.
    ///
    private func pickerFailure(_ error: Error) {
        let authError = ASAuthorizationError(_nsError: error as NSError)

        switch authError.code {
        case .canceled:
            // The user cancelling the flow is not really an error, so we're not reporting or tracking
            // this as an error.  We're only tracking this as a regular UI dismissal.
            tracker.track(click: .dismiss)
        case .failed:
            fallthrough
        case .invalidResponse:
            fallthrough
        case .notHandled:
            fallthrough
        case .unknown:
            tracker.track(failure: authError.localizedDescription)
            DDLogError("ASAuthorizationError: \(authError.localizedDescription)")
        }
    }
}

@available(iOS 13, *)
extension StoredCredentialsAuthenticator: LoginFacadeDelegate {
    func needsMultifactorCode() {
        print(">>>>>>>>>>>>>>>>> Needs multifactor code!")
    }
    
    func finishedLogin(withAuthToken authToken: String, requiredMultifactorCode: Bool) {
        print(">>>>>>>>>>>>>>>>> Success!!!!")
    }
}
