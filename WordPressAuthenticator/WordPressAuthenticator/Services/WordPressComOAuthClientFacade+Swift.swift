import Foundation
import WordPressKit

extension WordPressComOAuthClientFacade {

    var client: WordPressComOAuthClient {
        fatalError("To Be Replaced")
    }

    func authenticate(
        username: String,
        password: String,
        multifactorCode: String?,
        success: @escaping (_ authToken: String?) -> Void,
        needsMultifactor: ((_ userID: Int, _ nonceInfo: SocialLogin2FANonceInfo?) -> Void)?,
        failure: ((_ error: Error) -> Void)?
    ) {
        self.client.authenticateWithUsername(username, password: password, multifactorCode: multifactorCode, needsMultifactor: needsMultifactor, success: success, failure: { error in
            if error.code == WordPressComOAuthError.needsMultifactorCode.rawValue {
                needsMultifactor?(0, nil)
            } else {
                failure?(error)
            }
        })
    }

    func requestOneTimeCode(
        username: String,
        password: String,
        success: @escaping () -> Void,
        failure: @escaping (_ error: NSError) -> Void
    ) {
        self.client.requestOneTimeCodeWithUsername(username, password: password, success: success, failure: failure)
    }

    func requestSocial2FACode(
        userID: Int,
        nonce: String,
        success: @escaping (_ newNonce: String) -> Void,
        failure: @escaping (_ error: NSError, _ newNonce: String?) -> Void
    ) {
        self.client.requestSocial2FACodeWithUserID(userID, nonce: nonce, success: success, failure: failure)
    }

}

// MARK: - This extension is needed because WordPressComOAuthClientFacade cannot access the WordPressAuthenticatorConfiguration struct.
//
extension WordPressComOAuthClientFacade {
    @objc public static func initializeOAuthClient(clientID: String, secret: String) -> WordPressComOAuthClient {
        return WordPressComOAuthClient(clientID: clientID,
                                       secret: secret,
                                       wordPressComBaseUrl: WordPressAuthenticator.shared.configuration.wpcomBaseURL,
                                       wordPressComApiBaseUrl: WordPressAuthenticator.shared.configuration.wpcomAPIBaseURL)
    }
}
