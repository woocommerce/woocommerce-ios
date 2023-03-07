import Foundation
import Alamofire

/// Wraps up a URLRequestConvertible Instance, and injects the application password + `Settings.userAgent` whenever the actual Request is required.
///
struct AuthenticatedRESTRequest: URLRequestConvertible {
    /// Authenticated Request
    ///
    let request: URLRequest

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

    /// Returns the Wrapped Request, but with the application password injected
    ///
    func asURLRequest() -> URLRequest {
        request
    }
}
