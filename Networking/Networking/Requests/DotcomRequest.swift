import Foundation
import Alamofire


/// Represents a WordPress.com Request
///
struct DotcomRequest: URLRequestConvertible {

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

    /// WPCom Sandbox username, so the public WordPress.com API can be routed. If nil it will be ignored
    ///
    let wpComSandboxUsername: String?


    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - wordpressApiVersion: Endpoint Version.
    ///     - method: HTTP Method we should use.
    ///     - path: RPC that should be executed.
    ///     - parameters: Collection of String parameters to be passed over to our target RPC.
    ///
    init(wordpressApiVersion: WordPressAPIVersion, method: HTTPMethod, path: String, parameters: [String: Any]? = nil, wpComSandboxUsername: String? = nil) {
        self.wordpressApiVersion = wordpressApiVersion
        self.method = method
        self.path = path
        self.wpComSandboxUsername = wpComSandboxUsername
        self.parameters = parameters ?? [:]
    }

    /// Returns a URLRequest instance representing the current WordPress.com Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let dotcomURL = URL(string: Settings.wordpressApiBaseURL(wpComSandboxUsername: wpComSandboxUsername) + wordpressApiVersion.path + path)!
        let dotcomRequest = try URLRequest(url: dotcomURL, method: method, headers: nil)

        return try URLEncoding.default.encode(dotcomRequest, with: parameters)
    }
}
