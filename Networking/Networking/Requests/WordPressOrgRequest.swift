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
    var parameters: [String: Any]?


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
