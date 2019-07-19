import Foundation


/// WordPress.com Request Error
///
public enum DotcomError: Error, Decodable {

    /// Non explicit reason
    ///
    case empty

    /// Missing Token or no permission
    ///
    case unauthorized(message: String?)

    /// We're not properly authenticated
    ///
    case invalidToken

    /// Remote Request Failed
    ///
    case requestFailed

    /// No route was found matching the URL and request method
    ///
    case noRestRoute

    /// Unknown: Represents an unmapped remote error. Capisce?
    ///
    case unknown(code: String, message: String?)



    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let error = try container.decode(String.self, forKey: .error)
        let message = try container.decodeIfPresent(String.self, forKey: .message)

        switch error {
        case Constants.invalidToken:
            self = .invalidToken
        case Constants.requestFailed:
            self = .requestFailed
        case Constants.unauthorized:
            self = .unauthorized(message: message)
        case Constants.noRestRoute:
            self = .noRestRoute
        default:
            self = .unknown(code: error, message: message)
        }
    }


    /// Constants
    ///
    private enum Constants {
        static let unauthorized     = "unauthorized"
        static let invalidToken     = "invalid_token"
        static let requestFailed    = "http_request_failed"
        static let noRestRoute      = "rest_no_route"
    }

    /// Coding Keys
    ///
    private enum CodingKeys: String, CodingKey {
        case error
        case message
    }
}


// MARK: - CustomStringConvertible Conformance
//
extension DotcomError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .empty:
            return NSLocalizedString("Dotcom Response Empty", comment: "WordPress.com Error thrown when the response body is empty")
        case .invalidToken:
            return NSLocalizedString("Dotcom Token Invalid", comment: "WordPress.com Invalid Token")
        case .requestFailed:
            return NSLocalizedString("Dotcom Request Failed", comment: "WordPress.com Request Failure")
        case .unauthorized:
            return NSLocalizedString("Dotcom Missing Token", comment: "WordPress.com Missing Token")
        case .noRestRoute:
            return NSLocalizedString("Dotcom Invalid REST Route", comment: "WordPress.com error thrown when the the request REST API url is invalid.")
        case .unknown(let code, let message):
            let theMessage = message ?? String()
            return NSLocalizedString("Dotcom Error: [\(code)] \(theMessage)", comment: "WordPress.com (unmapped!) error")
        }
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: DotcomError, rhs: DotcomError) -> Bool {
    switch (lhs, rhs) {
    case (.requestFailed, .requestFailed):
        return true
    case (.unauthorized, .unauthorized):
        return true
    case (.noRestRoute, .noRestRoute):
        return true
    case let (.unknown(codeLHS, _), .unknown(codeRHS, _)):
        return codeLHS == codeRHS
    default:
        return false
    }
}
