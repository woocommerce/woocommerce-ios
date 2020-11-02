import Foundation
import Alamofire


/// Wraps up a URLRequestConvertible Instance, and injects the Credentials + `Settings.userAgent` whenever the actual Request is required.
///
struct AuthenticatedRequest: URLRequestConvertible {

    /// WordPress.com Credentials.
    ///
    let credentials: Credentials

    /// Request that should be authenticated.
    ///
    let request: URLRequestConvertible


    /// Returns the Wrapped Request, but with a WordPress.com Bearer Token set up.
    ///
    func asURLRequest() throws -> URLRequest {
        var authenticated = try request.asURLRequest()

        authenticated.setValue("Bearer " + credentials.authToken, forHTTPHeaderField: "Authorization")
        authenticated.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticated.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        return authenticated
    }
}
