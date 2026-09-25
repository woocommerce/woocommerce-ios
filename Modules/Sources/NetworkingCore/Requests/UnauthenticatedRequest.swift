import Foundation
import protocol Alamofire.URLRequestConvertible

/// Wraps up a `URLRequestConvertible` instance, and injects the `UserAgent.defaultUserAgent`.
///
public struct UnauthenticatedRequest: Request {

    /// Request that does not require WPCOM authentication.
    ///
    public let request: URLRequest
    let isMerchantRESTRequest: Bool

    public init(request: URLRequest, isMerchantRESTRequest: Bool = false) {
        self.request = request
        self.isMerchantRESTRequest = isMerchantRESTRequest
    }

    /// Returns the wrapped request, with a custom user-agent header.
    ///
    public func asURLRequest() -> URLRequest {
        var unauthenticated = request

        unauthenticated.setValue("application/json", forHTTPHeaderField: "Accept")
        unauthenticated.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        return unauthenticated
    }

    public func responseDataValidator() -> ResponseDataValidator {
        PlaceholderDataValidator()
    }
}
