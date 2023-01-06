import Foundation
import Alamofire

/// Represents a WordPress.org REST API request
///
struct RESTRequest: Request {
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
         wooApiVersion: WooAPIVersion = .none,
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
        let components = [siteURL, Settings.basePath, wooApiVersion.path, path]
            .map { $0.trimSlashes() }
            .filter { $0.isEmpty == false }
        let url = try components.joined(separator: "/").asURL()
        let request = try URLRequest(url: url, method: method)
        switch method {
        case .post, .put:
            return try JSONEncoding.default.encode(request, with: parameters)
        default:
            return try URLEncoding.default.encode(request, with: parameters)
        }
    }

    func responseDataValidator() -> ResponseDataValidator {
        PlaceholderDataValidator()
    }
}

extension RESTRequest {
    enum Settings {
        static let basePath = "wp-json"
    }
}
