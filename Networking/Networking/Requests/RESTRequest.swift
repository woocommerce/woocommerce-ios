import Foundation
import Alamofire

struct RESTRequest: URLRequestConvertible {
    /// URL of the site to make the request with
    ///
    let siteURL: String

    /// HTTP Request Method
    ///
    let method: HTTPMethod

    /// RPC
    ///
    let path: String

    /// Parameters
    ///
    let parameters: [String: Any]?

    /// HTTP Headers
    let headers: [String: String]

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - method: HTTP Method we should use.
    ///     - path: RPC that should be executed.
    ///     - parameters: Collection of String parameters to be passed over to our target RPC.
    ///
    init(siteURL: String, method: HTTPMethod, path: String, parameters: [String: Any]? = nil, headers: [String: String]? = nil) {
        self.siteURL = siteURL
        self.method = method
        self.path = path
        self.parameters = parameters ?? [:]
        self.headers = headers ?? [:]
    }

    /// Returns a URLRequest instance representing the current WordPress.com Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let url = try (siteURL + path).asURL()
        let request = try URLRequest(url: url, method: method, headers: headers)

        return try URLEncoding.default.encode(request, with: parameters)
    }
}
