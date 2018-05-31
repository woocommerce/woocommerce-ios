import Foundation
import Alamofire


/// Represents a Jetpack-Tunneled WordPress.com Endpoint
///
struct JetpackRequest: URLRequestConvertible  {

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
    let siteID: Int

    /// Jetpack-Tunneled RPC
    ///
    let path: String

    /// Jetpack-Tunneled Parameters
    ///
    let parameters: [String: String]


    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - wooApiVersion: Version of the Woo Endpoint that will be hit.
    ///     - method: HTTP Method we should use.
    ///     - siteID: Identifier of the Jetpack-Connected site we'll query.
    ///     - path: RPC that should be called.
    ///     - parameters: Collection of Key/Value parameters, to be forwarded to the Jetpack Connected site.
    ///
    init(wooApiVersion: WooAPIVersion, method: HTTPMethod, siteID: Int, path: String, parameters: [String: String]? = nil) {
        self.wooApiVersion = wooApiVersion
        self.method = method
        self.siteID = siteID
        self.path = path
        self.parameters = parameters ?? [:]
    }


    /// Returns a URLRequest instance reprensenting the current Jetpack Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let dotcomEndpoint = DotcomRequest(wordpressApiVersion: JetpackRequest.wordpressApiVersion, method: method, path: dotcomPath)
        let dotcomRequest = try dotcomEndpoint.asURLRequest()

        return try dotcomEncoder.encode(dotcomRequest, with: dotcomParams)
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
        return method == .get ? URLEncoding.queryString : URLEncoding.httpBody
    }

    /// Returns the WordPress.com Parameters
    ///
    var dotcomParams: [String: String] {
        var output = [
            "_method"   : method.rawValue.lowercased(),
            "path"      : jetpackPath + jetpackQueryParams,
            "json"      : "true"
        ]

        if let jetpackBodyParams = jetpackBodyParams {
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
        return method == .get
    }

    /// Returns the Jetpack-Tunneled-Request's Parameters
    ///
    var jetpackQueryParams: String {
        guard jetpackEncodesParametersInQuery else {
            return String()
        }

        return parameters.reduce("") { (output, parameter) in
            output + "&" + parameter.key + "=" + String(describing: parameter.value)
        }
    }

    /// Returns the Jetpack-Tunneled-Request's Body parameters
    ///
    var jetpackBodyParams: String? {
        guard jetpackEncodesParametersInQuery == false else {
            return nil
        }

        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(parameters)

        return String(data: encoded, encoding: .utf8)
    }
}
