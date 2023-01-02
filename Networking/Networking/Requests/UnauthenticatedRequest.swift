import Foundation
import protocol Alamofire.URLRequestConvertible

/// Wraps up a `URLRequestConvertible` instance, and injects the `UserAgent.defaultUserAgent`.
///
struct UnauthenticatedRequest: URLRequestConvertible {

    /// Request that does not require WPCOM authentication.
    ///
    let request: URLRequest

    /// Returns the wrapped request, with a custom user-agent header.
    ///
    func asURLRequest() -> URLRequest {
        var unauthenticated = request

        unauthenticated.setValue("application/json", forHTTPHeaderField: "Accept")
        unauthenticated.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        return unauthenticated
    }
}
