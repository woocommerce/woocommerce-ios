import Foundation
import Alamofire

/// Represents a WooCommerce Store API request for Point of Sale operations.
///
/// This request type wraps a standard REST request and adds the `X-WC-POS: 1` header
/// required for POS Store API operations.
///
public struct POSStoreAPIRequest: Request {
    /// URL of the site to make the request with
    ///
    private let siteURL: String

    /// HTTP Request Method
    ///
    private let method: HTTPMethod

    /// Path to the target endpoint (relative to Store API version path)
    ///
    private let path: String

    /// Parameters
    ///
    private let parameters: [String: Any]?

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - siteURL: URL of the site to send the request to.
    ///     - method: HTTP Method to use.
    ///     - path: Path to the target endpoint (e.g., "cart", "checkout").
    ///     - parameters: Collection of parameters to be passed to the endpoint.
    ///
    public init(siteURL: String,
                method: HTTPMethod,
                path: String,
                parameters: [String: Any]? = nil) {
        self.siteURL = siteURL
        self.method = method
        self.path = path
        self.parameters = parameters
    }

    /// Returns a URLRequest instance representing the current POS Store API Request.
    ///
    public func asURLRequest() throws -> URLRequest {
        let components = [siteURL, Settings.basePath, WooAPIVersion.storeV1.path, path]
            .compactMap { $0 }
            .map { $0.trimSlashes() }
            .filter { $0.isEmpty == false }
        let url = try components.joined(separator: "/").asURL()

        var request = try URLRequest(url: url, method: method)

        // Add the POS header
        request.setValue(Settings.posHeaderValue, forHTTPHeaderField: Settings.posHeaderKey)

        // Encode parameters
        switch method {
        case .post, .put:
            return try JSONEncoding.default.encode(request, with: parameters)
        case .delete:
            // DELETE requests may have parameters in the URL
            return try URLEncoding.default.encode(request, with: parameters)
        default:
            return try URLEncoding.default.encode(request, with: parameters)
        }
    }

    public func responseDataValidator() -> ResponseDataValidator {
        PlaceholderDataValidator()
    }
}

// MARK: - Constants
//
private extension POSStoreAPIRequest {
    enum Settings {
        static let basePath = "?rest_route="
        static let posHeaderKey = "X-WC-POS"
        static let posHeaderValue = "1"
    }
}
