import Foundation
import Alamofire

/// Represents a WordPress.org REST API Endpoint
///
struct WordPressOrgRequest: URLRequestConvertible {

    /// Base URL for the endpoint
    ///
    let baseURL: String

    /// HTTP Request Method
    ///
    let method: HTTPMethod

    /// Path to endpoint
    ///
    let path: String

    /// Parameters
    ///
    let parameters: [String: Any]


    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - method: HTTP Method we should use.
    ///     - path: RPC that should be called.
    ///     - parameters: Collection of Key/Value parameters.
    ///
    init(baseURL: String, method: HTTPMethod, path: String, parameters: [String: Any]? = nil) {
        self.baseURL = baseURL
        self.method = method
        self.path = path
        self.parameters = parameters ?? [:]
    }


    /// Returns a URLRequest instance reprensenting the current Jetpack Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let url = URL(string: baseURL + Settings.basePath + path.removingPrefix("/"))!
        let request = try URLRequest(url: url, method: method, headers: nil)

        return try URLEncoding.default.encode(request, with: parameters)
    }
}

private extension WordPressOrgRequest {
    enum Settings {
        static let basePath = "/wp-json/"
    }
}
