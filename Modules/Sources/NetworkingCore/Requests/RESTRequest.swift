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

    let requestParameters: RequestParameters

    /// Whether this request should allow cellular access.
    ///
    let allowsCellularAccess: Bool

    private init(siteURL: String,
                 apiVersionPath: String?,
                 method: HTTPMethod,
                 path: String,
                 requestParameters: RequestParameterDictionary? = nil,
                 allowsCellularAccess: Bool = true) {
        self.siteURL = siteURL
        self.apiVersionPath = apiVersionPath
        self.method = method
        self.path = path
        self.requestParameters = RequestParameters(requestParameters)
        self.allowsCellularAccess = allowsCellularAccess
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///     - allowsCellularAccess: Whether the request should allow cellular data access.
    ///
    public init(siteURL: String,
         method: HTTPMethod,
         path: String,
         parameters: RequestParameterDictionary? = nil,
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL, apiVersionPath: nil, method: method, path: path, requestParameters: parameters, allowsCellularAccess: allowsCellularAccess)
    }

    public init<Value: RequestParameterValueConvertible>(siteURL: String,
         method: HTTPMethod,
         path: String,
         parameters: [String: Value],
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL,
                  apiVersionPath: nil,
                  method: method,
                  path: path,
                  requestParameters: parameters.requestParameterDictionary,
                  allowsCellularAccess: allowsCellularAccess)
    }

    public init(siteURL: String,
         method: HTTPMethod,
         path: String,
         parameters: RequestParameterConvertibleDictionary,
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL,
                  apiVersionPath: nil,
                  method: method,
                  path: path,
                  requestParameters: parameters.requestParameterDictionary,
                  allowsCellularAccess: allowsCellularAccess)
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - wooApiVersion: WooCommerce API version.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///     - allowsCellularAccess: Whether the request should allow cellular data access.
    ///
    init(siteURL: String,
         wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: RequestParameterDictionary? = nil,
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wooApiVersion.path,
                  method: method,
                  path: path,
                  requestParameters: parameters,
                  allowsCellularAccess: allowsCellularAccess)
    }

    init<Value: RequestParameterValueConvertible>(siteURL: String,
         wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Value],
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wooApiVersion.path,
                  method: method,
                  path: path,
                  requestParameters: parameters.requestParameterDictionary,
                  allowsCellularAccess: allowsCellularAccess)
    }

    init(siteURL: String,
         wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: RequestParameterConvertibleDictionary,
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wooApiVersion.path,
                  method: method,
                  path: path,
                  requestParameters: parameters.requestParameterDictionary,
                  allowsCellularAccess: allowsCellularAccess)
    }

    /// - Parameters:
    ///     - siteURL: URL of the site to send the REST request to.
    ///     - wordpressApiVersion: WordPress API version.
    ///     - method: HTTP Method we should use.
    ///     - path: path to the target endpoint.
    ///     - parameters: Collection of String parameters to be passed over to our target endpoint.
    ///     - allowsCellularAccess: Whether the request should allow cellular data access.
    ///
    // periphery:ignore - we include the cellular parameter for all inits
    init(siteURL: String,
         wordpressApiVersion: WordPressAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: RequestParameterDictionary? = nil,
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wordpressApiVersion.path,
                  method: method,
                  path: path,
                  requestParameters: parameters,
                  allowsCellularAccess: allowsCellularAccess)
    }

    init<Value: RequestParameterValueConvertible>(siteURL: String,
         wordpressApiVersion: WordPressAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Value],
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wordpressApiVersion.path,
                  method: method,
                  path: path,
                  requestParameters: parameters.requestParameterDictionary,
                  allowsCellularAccess: allowsCellularAccess)
    }

    init(siteURL: String,
         wordpressApiVersion: WordPressAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: RequestParameterConvertibleDictionary,
         allowsCellularAccess: Bool = true) {
        self.init(siteURL: siteURL,
                  apiVersionPath: wordpressApiVersion.path,
                  method: method,
                  path: path,
                  requestParameters: parameters.requestParameterDictionary,
                  allowsCellularAccess: allowsCellularAccess)
    }

    /// Returns a URLRequest instance representing the current REST API Request.
    ///
    public func asURLRequest() throws -> URLRequest {
        let rootComponents: [String?] = if let cachedRoot = WordPressRESTAPIRootCache.shared.root(for: siteURL) {
            [cachedRoot, apiVersionPath, path]
        } else {
            [siteURL, Settings.basePath, apiVersionPath, path]
        }
        let components = rootComponents
            .compactMap { $0 }
            .map { $0.trimSlashes() }
            .filter { $0.isEmpty == false }
        let url = try components.joined(separator: "/").asURL()
        var request = try URLRequest(url: url, method: method)
        request.allowsCellularAccess = allowsCellularAccess
        let parameters = try requestParameters.validatedAlamofireParameters()
        switch method {
        case .post, .put, .patch:
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
