import Foundation
import Alamofire

/// Represents a WordPress.org REST API request
///
public struct RESTRequest: Request {
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

    /// Whether this request should allow cellular access.
    ///
    let allowsCellularAccess: Bool

    /// Additional headers to include in the request
    ///
    let additionalHeaders: [String: String]

    private init(siteURL: String,
                 apiVersionPath: String?,
                 method: HTTPMethod,
                 path: String,
                 parameters: [String: Any]? = nil,
                 allowsCellularAccess: Bool = true,
                 additionalHeaders: [String: String] = [:]) {
        self.siteURL = siteURL
        self.apiVersionPath = apiVersionPath
        self.method = method
        self.path = path
        self.parameters = parameters
        self.allowsCellularAccess = allowsCellularAccess
        self.additionalHeaders = additionalHeaders
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///     - allowsCellularAccess: Whether the request should allow cellular data access.
    ///     - additionalHeaders: Additional HTTP headers to include in the request.
    ///
    public init(siteURL: String,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any]? = nil,
         allowsCellularAccess: Bool = true,
         additionalHeaders: [String: String] = [:]) {
        self.init(siteURL: siteURL, apiVersionPath: nil, method: method, path: path, parameters: parameters, allowsCellularAccess: allowsCellularAccess, additionalHeaders: additionalHeaders)
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - wooApiVersion: WooCommerce API version.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///     - allowsCellularAccess: Whether the request should allow cellular data access.
    ///     - additionalHeaders: Additional HTTP headers to include in the request.
    ///
    init(siteURL: String,
         wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any]? = nil,
         allowsCellularAccess: Bool = true,
         additionalHeaders: [String: String] = [:]) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wooApiVersion.path,
                  method: method,
                  path: path,
                  parameters: parameters,
                  allowsCellularAccess: allowsCellularAccess,
                  additionalHeaders: additionalHeaders)
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - wordpressApiVersion: WordPress API version.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///     - allowsCellularAccess: Whether the request should allow cellular data access.
    ///     - additionalHeaders: Additional HTTP headers to include in the request.
    ///
    // periphery:ignore - we include the cellular parameter for all inits
    init(siteURL: String,
         wordpressApiVersion: WordPressAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any]? = nil,
         allowsCellularAccess: Bool = true,
         additionalHeaders: [String: String] = [:]) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wordpressApiVersion.path,
                  method: method,
                  path: path,
                  parameters: parameters,
                  allowsCellularAccess: allowsCellularAccess,
                  additionalHeaders: additionalHeaders)
    }

    /// Returns a URLRequest instance representing the current REST API Request.
    ///
    public func asURLRequest() throws -> URLRequest {
        let components = [siteURL, Settings.basePath, apiVersionPath, path]
            .compactMap { $0 }
            .map { $0.trimSlashes() }
            .filter { $0.isEmpty == false }
        let url = try components.joined(separator: "/").asURL()
        var request = try URLRequest(url: url, method: method)
        request.allowsCellularAccess = allowsCellularAccess

        // Add any additional headers
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        switch method {
        case .post, .put:
            return try JSONEncoding.default.encode(request, with: parameters)
        default:
            return try URLEncoding.default.encode(request, with: parameters)
        }
    }

    public func responseDataValidator() -> ResponseDataValidator {
        PlaceholderDataValidator()
    }
}

extension RESTRequest {
    enum Settings {
        static let basePath = "?rest_route="
    }
}
