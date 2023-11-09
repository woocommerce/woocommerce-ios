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
    case unacceptableStatusCode(statusCode: Int, response: String? = nil)

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
            let response: String? = {
                guard let responseData else {
                    return nil
                }
                return String(data: responseData, encoding: .utf8)
            }()
            self = .unacceptableStatusCode(statusCode: statusCode, response: response)
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
