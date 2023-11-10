import Foundation


/// Networking Errors
///
public enum NetworkError: Error, Equatable {

    /// Resource Not Found (statusCode = 404)
    ///
    case notFound

    /// Request Timeout (statusCode = 408)
    ///
    case timeout

    /// Any statusCode that's not in the [200, 300) range!
    ///
    case unacceptableStatusCode(statusCode: Int, response: Data? = nil)

    case invalidURL

    /// Error for REST API requests with invalid cookie nonce
    case invalidCookieNonce
}


// MARK: - Public Methods
//
extension NetworkError {

    /// Designated Initializer
    ///
    init?(responseData: Data?,
          statusCode: Int) {
        guard StatusCode.success.contains(statusCode) == false else {
            return nil
        }

        switch statusCode {
        case StatusCode.notFound:
            self = .notFound
        case StatusCode.timeout:
            self = .timeout
        default:
            self = .unacceptableStatusCode(statusCode: statusCode, response: responseData)
        }
    }

    /// Constants
    ///
    private enum StatusCode {
        static let success  = 200..<300
        static let notFound = 404
        static let timeout  = 408
    }
}
