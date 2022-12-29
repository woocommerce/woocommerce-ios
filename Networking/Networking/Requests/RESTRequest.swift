import Foundation
import Alamofire

/// Wraps up a URLRequestConvertible Instance, and injects the Authorization + User Agent whenever the actual Request is required.
///
struct RESTRequest: URLRequestConvertible {
    /// URL of the site to make the request with
    ///
    let siteURL: String

    /// WooCommerce API Version
    ///
    let wooApiVersion: WooAPIVersion

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
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///
    init(siteURL: String,
         wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any] = [:]) {
        self.siteURL = siteURL
        self.wooApiVersion = wooApiVersion
        self.method = method
        self.path = path
        self.parameters = parameters
    }

    /// Returns a URLRequest instance representing the current REST API Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let components = [siteURL, Settings.basePath, wooApiVersion.path, path].map { $0.trimSlashes() }
        let url = try components.joined(separator: "/").asURL()
        let request = try URLRequest(url: url, method: method)
        return try URLEncoding.default.encode(request, with: parameters)
    }

    /// Updates the request headers with authentication information.
    ///
    func authenticateRequest(with applicationPassword: ApplicationPassword) throws -> URLRequest {
        var request = try asURLRequest()
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let username = applicationPassword.wpOrgUsername
        let password = applicationPassword.password.secretValue
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            return request
        }
        let base64LoginString = loginData.base64EncodedString()

        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        return request
    }
}

extension RESTRequest {
    enum Settings {
        static let basePath = "wp-json"
    }
}
