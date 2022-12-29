import Foundation
import Alamofire

enum AuthenticatedRequestError: Error {
    case invalidCredentials
}

/// Wraps up a URLRequestConvertible Instance, and injects the Credentials + `Settings.userAgent` whenever the actual Request is required.
///
struct AuthenticatedRequest: URLRequestConvertible {
    /// Authenticated Request
    ///
    let request: URLRequest

    init(authToken: String, request: URLRequest) {
        var authenticated = request

        authenticated.setValue("Bearer " + authToken, forHTTPHeaderField: "Authorization")
        authenticated.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticated.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        self.request = authenticated
    }

    init(applicationPassword: ApplicationPassword, request: URLRequest) {
        var authenticated = request
        
        authenticated.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticated.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let username = applicationPassword.wpOrgUsername
        let password = applicationPassword.password.secretValue
        let loginString = "\(username):\(password)"

        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            authenticated.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }

        // Cookies from `CookieNonceAuthenticator` should be skipped
        authenticated.httpShouldHandleCookies = false
        self.request = authenticated
    }

    /// Returns the Wrapped Request, but with a WordPress.com Bearer Token set up.
    ///
    func asURLRequest() -> URLRequest {
        request
    }
}
