import Foundation
import Alamofire


/// Represents a WordPress.com Request
///
struct DotcomRequest: URLRequestConvertible {

    /// WordPress.com Base URL
    ///
    let wordpressApiBaseURL: String

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
    let parameters: [String: Any]?


    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - wordpressApiVersion: Endpoint Version.
    ///     - method: HTTP Method we should use.
    ///     - path: RPC that should be executed.
    ///     - parameters: Collection of String parameters to be passed over to our target RPC.
    ///
    init(wordpressApiVersion: WordPressAPIVersion, method: HTTPMethod, path: String, parameters: [String: Any]? = nil) {
        self.wordpressApiVersion = wordpressApiVersion
        self.method = method
        self.path = path
        self.parameters = parameters ?? [:]
        self.wordpressApiBaseURL = UserDefaults.standard.string(forKey: "wpcom-api-base-url") ?? "https://public-api.wordpress.com/"
    }

    /// Returns a URLRequest instance representing the current WordPress.com Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let dotcomURL = URL(string: wordpressApiBaseURL + wordpressApiVersion.path + path)!
        let dotcomRequest = try URLRequest(url: dotcomURL, method: method, headers: nil)

        return try URLEncoding.default.encode(dotcomRequest, with: parameters)
    }
}
