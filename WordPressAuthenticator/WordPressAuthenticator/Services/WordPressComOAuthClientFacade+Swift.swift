import Foundation
import WordPressKit

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
