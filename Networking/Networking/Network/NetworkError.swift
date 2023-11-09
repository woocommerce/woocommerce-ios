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
    case unacceptableStatusCode(statusCode: Int, response: Data?)

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

extension NetworkError: CustomStringConvertible {
    public var description: String {
        switch self {
            case let .unacceptableStatusCode(statusCode, responseData):
                let response: String? = responseData.map { String(data: $0, encoding: .utf8) } ?? nil
                let format = NSLocalizedString(
                    "NetworkError.unacceptableStatusCode",
                    // TODO: a more user-friendly message?
                    value: "An error occurred with the server. (HTTP Status Code: %1$d). Response: %2$@",
                    comment: "Error message when the a network call fails with unacceptable status code." +
                    "%1$d is the status code like 500. %2$@ is the response string."
                )
                return String.localizedStringWithFormat(format, statusCode, response ?? "")
            case .timeout:
                return NSLocalizedString(
                    "NetworkError.timeout",
                    value: "The request timed out - please try again",
                    comment: "Error message when a request times out."
                )
            default:
                // TODO: error description for other cases
                return "TODO: \(self)"
        }
    }
}
