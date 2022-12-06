import Foundation
import protocol Alamofire.URLRequestConvertible


/// Wraps up a `URLRequestConvertible` instance, and injects the `UserAgent.defaultUserAgent`.
///
struct UnauthenticatedRequest: Request {

    /// Request that does not require WPCOM authentication.
    ///
    let request: Request

    /// Returns the wrapped request, with a custom user-agent header.
    ///
    func asURLRequest() throws -> URLRequest {
        var authenticated = try request.asURLRequest()

        authenticated.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticated.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        return authenticated
    }
}
