import Foundation
import Alamofire

struct WooRestApiRequest: Request {

    /// Base URL for the endpoint
    ///
    let baseURL: String

    /// Path to endpoint
    ///
    let path: String

    /// WooCommerce API Version
    ///
    let wooApiVersion: WooAPIVersion

    /// HTTP Request Method
    ///
    let method: HTTPMethod

    /// Parameters
    ///
    var parameters: [String: Any]?

    /// Returns a URLRequest instance reprensenting the current WordPress.org REST API Request.
    ///
    func asURLRequest() throws -> URLRequest {
        let url = URL(string: baseURL.removingSuffix("/") + Settings.basePath + wooApiVersion.path.removingPrefix("/") + path.removingPrefix("/"))!
        let request = try URLRequest(url: url, method: method, headers: nil)

        switch method {
        case .post:
            return try JSONEncoding.default.encode(request, with: parameters)
        default:
            return try URLEncoding.default.encode(request, with: parameters)
        }
    }

    func responseDataValidator() -> ResponseDataValidator {
        return WordPressApiValidator()
    }

    func asWordPressOrgRestAPIRequest() -> URLRequest? {
        nil
    }
}

private extension WooRestApiRequest {
    enum Settings {
        static let basePath = "/wp-json/"
    }
}
