import Foundation
import Alamofire


/// Represents a Jetpack-Tunneled WordPress.com Endpoint
///
public struct JetpackRequest: Request, RESTRequestConvertible {

    /// WordPress.com API Version: By Default, we'll go thru Mark 1.1.
    ///
    static let wordpressApiVersion = WordPressAPIVersion.mark1_1

    /// WooCommerce API Version
    ///
    let wooApiVersion: WooAPIVersion

    /// Jetpack-Tunneled HTTP Request Method
    ///
    let method: HTTPMethod

    /// Jetpack-Tunneled Site ID
    ///
    let siteID: Int64

    /// Locale identifier, simplified as `language_Region` e.g. `en_US`
    ///
    let locale: String?

    /// Jetpack-Tunneled RPC
    ///
    public let path: String

    let requestParameters: RequestParameters

    let queryParameters: RequestParameters

    /// Whether this request should be transformed to a REST request if application password is available.
    ///
    private let availableAsRESTRequest: Bool

    /// Whether this request should allow cellular access.
    ///
    private let allowsCellularAccess: Bool

    private init(wooApiVersion: WooAPIVersion,
                 method: HTTPMethod,
                 siteID: Int64,
                 locale: String? = nil,
                 path: String,
                 requestParameters: RequestParameters,
                 queryParameters: RequestParameters,
                 availableAsRESTRequest: Bool = false,
                 allowsCellularAccess: Bool = true) {
        if [.mark1, .mark2].contains(wooApiVersion) {
            DDLogWarn("⚠️ You are using an older version of the Woo REST API: \(wooApiVersion.rawValue), for path: \(path)")
        }
        self.wooApiVersion = wooApiVersion
        self.method = method
        self.siteID = siteID
        self.locale = locale
        self.path = path
        self.requestParameters = requestParameters
        self.queryParameters = queryParameters
        self.availableAsRESTRequest = availableAsRESTRequest
        self.allowsCellularAccess = allowsCellularAccess
    }

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - wooApiVersion: Version of the Woo Endpoint that will be hit.
    ///     - method: HTTP Method we should use.
    ///     - siteID: Identifier of the Jetpack-Connected site we'll query.
    ///     - path: RPC that should be called.
    ///     - parameters: Collection of Key/Value parameters, to be forwarded to the Jetpack Connected site.
    ///     - queryParameters: Collection of Key/Value parameters to encode in the endpoint URL.
    ///     - availableAsRESTRequest: Whether the request should be transformed to a REST request if application password is available.
    ///     - allowsCellularAccess: Whether the request should allow cellular data access.
    ///
    public init(wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         siteID: Int64,
         locale: String? = nil,
         path: String,
         parameters: RequestParameterDictionary? = nil,
         queryParameters: RequestParameterDictionary? = nil,
         availableAsRESTRequest: Bool = false,
         allowsCellularAccess: Bool = true) {
        self.init(wooApiVersion: wooApiVersion,
                  method: method,
                  siteID: siteID,
                  locale: locale,
                  path: path,
                  requestParameters: RequestParameters(parameters),
                  queryParameters: RequestParameters(queryParameters),
                  availableAsRESTRequest: availableAsRESTRequest,
                  allowsCellularAccess: allowsCellularAccess)
    }

    public init<Value: RequestParameterValueConvertible>(wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         siteID: Int64,
         locale: String? = nil,
         path: String,
         parameters: [String: Value],
         queryParameters: RequestParameterDictionary? = nil,
         availableAsRESTRequest: Bool = false,
         allowsCellularAccess: Bool = true) {
        self.init(wooApiVersion: wooApiVersion,
                  method: method,
                  siteID: siteID,
                  locale: locale,
                  path: path,
                  requestParameters: RequestParameters(parameters),
                  queryParameters: RequestParameters(queryParameters),
                  availableAsRESTRequest: availableAsRESTRequest,
                  allowsCellularAccess: allowsCellularAccess)
    }

    public init(wooApiVersion: WooAPIVersion,
         method: HTTPMethod,
         siteID: Int64,
         locale: String? = nil,
         path: String,
         parameters: RequestParameterConvertibleDictionary,
         queryParameters: RequestParameterDictionary? = nil,
         availableAsRESTRequest: Bool = false,
         allowsCellularAccess: Bool = true) {
        self.init(wooApiVersion: wooApiVersion,
                  method: method,
                  siteID: siteID,
                  locale: locale,
                  path: path,
                  requestParameters: RequestParameters(parameters),
                  queryParameters: RequestParameters(queryParameters),
                  availableAsRESTRequest: availableAsRESTRequest,
                  allowsCellularAccess: allowsCellularAccess)
    }


    /// Returns a URLRequest instance reprensenting the current Jetpack Request.
    ///
    public func asURLRequest() throws -> URLRequest {
        let dotcomEndpoint = DotcomRequest(wordpressApiVersion: JetpackRequest.wordpressApiVersion, method: dotcomMethod, path: dotcomPath)
        var dotcomRequest = try dotcomEndpoint.asURLRequest()
        dotcomRequest.allowsCellularAccess = allowsCellularAccess

        return try dotcomEncoder.encode(dotcomRequest, with: dotcomParams())
    }

    public func responseDataValidator() -> ResponseDataValidator {
        return DotcomValidator()
    }

    func asRESTRequest(with siteURL: String) -> RESTRequest? {
        guard availableAsRESTRequest else {
            return nil
        }

        return RESTRequest(siteURL: siteURL,
                           wooApiVersion: wooApiVersion,
                           method: method,
                           path: path,
                           parameters: requestParameters.dictionary,
                           queryParameters: queryParameters.dictionary,
                           allowsCellularAccess: allowsCellularAccess)
    }
}


// MARK: - Dotcom Request: Internal
//
private extension JetpackRequest {

    /// Returns the WordPress.com Tunneling Request
    ///
    var dotcomPath: String {
        return "jetpack-blogs/" + String(siteID) + "/rest-api/"
    }

    /// Returns the WordPress.com Parameters Encoder
    ///
    var dotcomEncoder: ParameterEncoding {
        return dotcomMethod == .get ? URLEncoding.queryString : URLEncoding.httpBody
    }

    /// Returns the WordPress.com HTTP Method
    ///
    var dotcomMethod: HTTPMethod {
        // If we are calling DELETE via a tunneled connection, use GET instead (DELETE will be added to the `_method` query string param)
        // Likewise, PUT requests should be sent as POST for the tunneled request
        switch method {
        case .get, .delete:
            return .get
        case .post, .put:
            return .post
        default:
            return method
        }
    }

    /// Returns the WordPress.com Parameters
    ///
    func dotcomParams() throws -> [String: String] {
        var output = [
            "json": "true",
            "path": try jetpackPathWithQueryParameters() + "&_method=" + method.rawValue.lowercased()
        ]

        if let locale {
            output["locale"] = locale
        }

        if let jetpackQueryParams = try jetpackQueryParams() {
            output["query"] = jetpackQueryParams
        }

        if let jetpackBodyParams = try jetpackBodyParams() {
            output["body"] = jetpackBodyParams
        }

        return output
    }
}


// MARK: - Jetpack Tunneled Request: Internal
//
private extension JetpackRequest {

    /// Returns the Jetpack-Tunneled-Request's Path
    ///
    var jetpackPath: String {
        return wooApiVersion.path + path
    }

    /// Indicates if the Jetpack Tunneled Request should encode it's parameters in the Query (or Body)
    ///
    var jetpackEncodesParametersInQuery: Bool {
        return dotcomMethod == .get
    }

    /// Returns the Jetpack-Tunneled-Request's Parameters
    ///
    func jetpackQueryParams() throws -> String? {
        guard jetpackEncodesParametersInQuery else {
            return nil
        }

        var parameters = try requestParameters.validatedDictionaryOrEmpty()
        if method == .get {
            parameters.merge(try queryParameters.validatedDictionaryOrEmpty()) { _, queryValue in queryValue }
        }
        return parameters.isEmpty ? nil : parameters.toJSONEncoded()
    }

    /// Returns the Jetpack-Tunneled-Request's Body parameters
    ///
    func jetpackBodyParams() throws -> String? {
        guard jetpackEncodesParametersInQuery == false else {
            return nil
        }

        return try requestParameters.validatedDictionaryOrEmpty().toJSONEncoded()
    }

    /// Returns the endpoint path with explicit query parameters encoded for the Jetpack tunnel.
    ///
    func jetpackPathWithQueryParameters() throws -> String {
        guard method != .get, let parameters = try queryParameters.validatedAlamofireParameters() else {
            return jetpackPath
        }

        guard let query = try urlEncodedQuery(from: parameters), query.isEmpty == false else {
            return jetpackPath
        }
        return jetpackPath + "&" + query
    }

    /// Uses a disposable request to reuse Alamofire's query encoding. The placeholder URL is never sent.
    ///
    func urlEncodedQuery(from parameters: Parameters) throws -> String? {
        let request = URLRequest(url: try "https://localhost".asURL())
        return try URLEncoding.queryString.encode(request, with: parameters).url?.query
    }
}
