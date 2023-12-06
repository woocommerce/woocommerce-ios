import Foundation
import Alamofire

/// Represents a WordPress.org REST API request
///
struct RESTRequest: Request {
    /// URL of the site to make the request with
    ///
    let siteURL: String

    /// WooCommerce / WordPress API Version Path
    ///
    let apiVersionPath: String?

    /// HTTP Request Method
    ///
    let method: HTTPMethod

    /// RPC
    ///
    let path: String

    /// Parameters
    ///
    let parameters: [String: Any]?

    /// Whether the request body should be kept empty
    ///
    let skipsEncodingBody: Bool

    private init(siteURL: String,
                 apiVersionPath: String?,
                 method: HTTPMethod,
                 path: String,
                 parameters: [String: Any],
                 skipsEncodingBody: Bool = false) {
        self.siteURL = siteURL
        self.apiVersionPath = apiVersionPath
        self.method = method
        self.path = path
        self.parameters = parameters
        self.skipsEncodingBody = skipsEncodingBody
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///
    init(siteURL: String,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any] = [:],
         skipsEncodingBody: Bool = false) {
        self.init(siteURL: siteURL,
                  apiVersionPath: nil,
                  method: method,
                  path: path,
                  parameters: parameters,
                  skipsEncodingBody: skipsEncodingBody)
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - wooApiVersion: WooCommerce API version.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///
    init(siteURL: String,
         wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any] = [:],
         skipsEncodingBody: Bool = false) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wooApiVersion.path,
                  method: method,
                  path: path,
                  parameters: parameters,
                  skipsEncodingBody: skipsEncodingBody)
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - wordpressApiVersion: WordPress API version.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///
    init(siteURL: String,
         wordpressApiVersion: WordPressAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any] = [:],
         skipsEncodingBody: Bool = false) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wordpressApiVersion.path,
                  method: method,
                  path: path,
                  parameters: parameters,
                  skipsEncodingBody: skipsEncodingBody)
    }

    /// Returns a URLRequest instance representing the current REST API Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let components = [siteURL, Settings.basePath, apiVersionPath, path]
            .compactMap { $0 }
            .map { $0.trimSlashes() }
            .filter { $0.isEmpty == false }
        let url = try components.joined(separator: "/").asURL()
        let request = try URLRequest(url: url, method: method)
        guard !skipsEncodingBody else {
            return request
        }
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
        static let basePath = "?rest_route="
    }
}
