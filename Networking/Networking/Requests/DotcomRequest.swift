import Foundation
import Alamofire

/// Represents a WordPress.com Request
///
struct ExternalRequest: Request {
    /// HTTP Request Method
    ///
    let method: HTTPMethod

    let url: String

    /// Parameters
    ///
    let parameters: [String: Any]?

    /// HTTP Headers
    let headers: [String: String]

    /// Initializer.
    ///
    /// - Parameters:
    ///     - method: HTTP Method we should use.
    ///     - url: Destination URL.
    ///     - parameters: Collection of String parameters to be passed over to our target RPC.
    ///     - headers: Headers used in the URLRequest.
    ///
    init(method: HTTPMethod,
         url: String,
         parameters: [String: Any]? = nil,
         headers: [String: String]? = nil) {
        self.method = method
        self.url = url
        self.parameters = parameters ?? [:]
        self.headers = headers ?? [:]
    }

    /// Returns a URLRequest instance representing the current WordPress.com Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let dotcomURL = URL(string: url)!
        let request = try URLRequest(url: dotcomURL, method: method, headers: headers)
        return try URLEncoding.httpBody.encode(request, with: parameters)
    }

    func responseDataValidator() -> ResponseDataValidator {
        PlaceholderDataValidator()
    }
}


enum DotcomRequestError: Error {
    case apiVersionCannotBeAccessedUsingRESTAPI
}

/// Represents a WordPress.com Request
///
struct DotcomRequest: Request, RESTRequestConvertible {

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

    /// HTTP Headers
    let headers: [String: String]

    /// Allows custom encoding for the parameters.
    private let encoding: ParameterEncoding

    /// Whether this request should be transformed to a REST request if application password is available.
    ///
    private let availableAsRESTRequest: Bool

    /// Initializer.
    ///
    /// - Parameters:
    ///     - wordpressApiVersion: Endpoint Version.
    ///     - method: HTTP Method we should use.
    ///     - path: RPC that should be executed.
    ///     - parameters: Collection of String parameters to be passed over to our target RPC.
    ///     - headers: Headers used in the URLRequest
    ///     - encoding: How the parameters are encoded. Default to use `URLEncoding`.
    ///
    init(wordpressApiVersion: WordPressAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any]? = nil,
         headers: [String: String]? = nil,
         encoding: ParameterEncoding = URLEncoding.default) {
        self.wordpressApiVersion = wordpressApiVersion
        self.method = method
        self.path = path
        self.parameters = parameters ?? [:]
        self.headers = headers ?? [:]
        self.encoding = encoding
        self.availableAsRESTRequest = false
    }

    /// Initializer.
    ///
    /// - Parameters:
    ///     - wordpressApiVersion: Endpoint Version.
    ///     - method: HTTP Method we should use.
    ///     - path: RPC that should be executed.
    ///     - parameters: Collection of String parameters to be passed over to our target RPC.
    ///     - headers: Headers used in the URLRequest
    ///     - availableAsRESTRequest: Whether the request should be transformed to a REST request if application password is available.
    ///
    init(wordpressApiVersion: WordPressAPIVersion,
         method: HTTPMethod,
         path: String,
         parameters: [String: Any]? = nil,
         headers: [String: String]? = nil,
         encoding: ParameterEncoding = URLEncoding.default,
         availableAsRESTRequest: Bool) throws {
        if availableAsRESTRequest && !wordpressApiVersion.isWPOrgEndpoint {
            throw DotcomRequestError.apiVersionCannotBeAccessedUsingRESTAPI
        }

        self.wordpressApiVersion = wordpressApiVersion
        self.method = method
        self.path = path
        self.parameters = parameters ?? [:]
        self.headers = headers ?? [:]
        self.encoding = encoding
        self.availableAsRESTRequest = availableAsRESTRequest
    }

    /// Returns a URLRequest instance representing the current WordPress.com Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let dotcomURL = URL(string: Settings.wordpressApiBaseURL + wordpressApiVersion.path + path)!
        let dotcomRequest = try URLRequest(url: dotcomURL, method: method, headers: headers)
        return try encoding.encode(dotcomRequest, with: parameters)
    }

    func responseDataValidator() -> ResponseDataValidator {
        switch wordpressApiVersion {
        case .mark1_1, .mark1_2, .mark1_3, .mark1_5:
            return DotcomValidator()
        case .wpcomMark2, .wpMark2:
            return WordPressApiValidator()
        }
    }

    func asRESTRequest(with siteURL: String) -> RESTRequest? {
        guard availableAsRESTRequest else {
            return nil
        }

        guard wordpressApiVersion.isWPOrgEndpoint else {
            return nil
        }

        // As the REST request is directly sent to the site URL, we remove site info from path
        guard let pathWithoutSiteInfo = try? pathAfterRemovingSitesComponent() else {
            return nil
        }

        return RESTRequest(siteURL: siteURL,
                           wooApiVersion: .none,
                           method: method,
                           path: wordpressApiVersion.path + pathWithoutSiteInfo,
                           parameters: parameters ?? [:])
    }
}

private extension DotcomRequest {
    /// Removes the site info from the `path`
    ///
    /// - Returns: Path without `sites/$siteID/`
    ///
    func pathAfterRemovingSitesComponent() throws -> String {
        let regex = try NSRegularExpression(pattern: "([\\/]*sites\\/.[^\\/]*\\/)")
        let range = NSRange(location: 0, length: path.count)
        return regex.stringByReplacingMatches(in: path, range: range, withTemplate: "")
    }
}
