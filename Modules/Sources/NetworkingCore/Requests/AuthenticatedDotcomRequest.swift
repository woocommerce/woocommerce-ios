import Foundation
import Alamofire

/// Wraps up a URLRequestConvertible Instance, and injects
/// the WordPress.com authentication token + `Settings.userAgent`
/// whenever the actual Request is required.
///
public struct AuthenticatedDotcomRequest: URLRequestConvertible {
    /// Authenticated Request
    ///
    public let request: URLRequest

    init(authToken: String, request: URLRequest) {
        var authenticated = request

        authenticated.setValue("Bearer " + authToken, forHTTPHeaderField: "Authorization")
        authenticated.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticated.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        self.request = authenticated
    }

    /// Returns the Wrapped Request, but with a WordPress.com Bearer Token set up.
    ///
    public func asURLRequest() -> URLRequest {
        request
    }
}
