import Foundation
import Alamofire


/// Represents a WordPress.com Request
///
struct DotcomRequest: URLRequestConvertible  {

    /// WordPress.com Base URL
    ///
    let wordpressApiBaseURL = "https://public-api.wordpress.com/"

    /// WordPress.com API Version
    ///
    let wordpressApiVersion: WordPressAPIVersion

    /// HTTP Request Method
    ///
    let method: HTTPMethod

    /// RPC
    ///
    let path: String

    /// Parameters
    ///
    let parameters: [String: String]?


    ///
    ///
    init(wordpressApiVersion: WordPressAPIVersion, method: HTTPMethod, path: String, parameters: [String: String]? = nil) {
        self.wordpressApiVersion = wordpressApiVersion
        self.method = method
        self.path = path
        self.parameters = parameters ?? [:]
    }


    /// Returns a URLRequest instance reprensenting the current WordPress.com Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let dotcomURL = URL(string: wordpressApiBaseURL + wordpressApiVersion.path + path)!
        let dotcomRequest = try URLRequest(url: dotcomURL, method: method, headers: nil)

        return try URLEncoding.default.encode(dotcomRequest, with: parameters)
    }
}
