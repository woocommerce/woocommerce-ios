import Foundation
import protocol Alamofire.URLRequestConvertible

enum WooRestAPIRequestError: Error {
    case failedToCreateCredentials
}

struct WooRESTKeyAuthenticatedRequest: URLRequestConvertible {

    /// WordPress.com Credentials.
    ///
    let credentials: WooRestAPICredentials

    /// Request that does not require WPCOM authentication.
    ///
    let request: URLRequestConvertible

    /// Returns the wrapped request, with a custom user-agent header.
    ///
    func asURLRequest() throws -> URLRequest {
        var authenticated = try request.asURLRequest()

        guard let credential = authorizationHeader(consumer_key: credentials.consumer_key, consumer_secret: credentials.consumer_secret) else {
            throw WooRestAPIRequestError.failedToCreateCredentials
        }

        authenticated.setValue(credential, forHTTPHeaderField: "Authorization")
        authenticated.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticated.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        return authenticated
    }

    private func authorizationHeader(consumer_key: String, consumer_secret: String) -> String? {
        guard let data = "\(consumer_key):\(consumer_secret)".data(using: .utf8) else { return nil }

        let credential = data.base64EncodedString(options: [])

        return "Basic \(credential)"
    }
}
