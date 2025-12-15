import Foundation
import Alamofire

/// Represents a WooCommerce Store API request for Point of Sale operations.
///
/// This request type wraps a `RESTRequest` and adds the `X-WC-POS: 1` header
/// required for POS Store API operations.
///
/// By wrapping `RESTRequest`, this request type is properly authenticated using
/// application passwords (Basic auth) instead of WPCOM token auth.
///
public struct POSStoreAPIRequest: Request {
    /// The underlying REST request
    ///
    private let restRequest: RESTRequest

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
        // Build the full path with Store API version
        let fullPath = [WooAPIVersion.storeV1.path, path]
            .map { $0.trimSlashes() }
            .filter { $0.isEmpty == false }
            .joined(separator: "/")

        self.restRequest = RESTRequest(
            siteURL: siteURL,
            method: method,
            path: fullPath,
            parameters: parameters,
            additionalHeaders: [Settings.posHeaderKey: Settings.posHeaderValue]
        )
    }

    /// Returns a URLRequest instance representing the current POS Store API Request.
    ///
    public func asURLRequest() throws -> URLRequest {
        // The POS header is included in the underlying REST request via additionalHeaders
        try restRequest.asURLRequest()
    }

    public func responseDataValidator() -> ResponseDataValidator {
        PlaceholderDataValidator()
    }
}

// MARK: - RESTRequestConvertible conformance for authentication
//
extension POSStoreAPIRequest: RESTRequestConvertible {
    func asRESTRequest(with siteAddress: String) -> RESTRequest? {
        // Return the underlying REST request for proper authentication handling
        restRequest
    }
}

// MARK: - Constants
//
private extension POSStoreAPIRequest {
    enum Settings {
        static let posHeaderKey = "X-WC-POS"
        static let posHeaderValue = "1"
    }
}
