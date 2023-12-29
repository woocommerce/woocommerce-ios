import Foundation


/// Networking Errors
///
public enum NetworkError: Error, Equatable {

    /// Resource Not Found (statusCode = 404)
    ///
    case notFound(response: Data? = nil)

    /// Request Timeout (statusCode = 408)
    ///
    case timeout(response: Data? = nil)

    /// Any statusCode that's not in the [200, 300) range!
    ///
    case unacceptableStatusCode(statusCode: Int, response: Data? = nil)

    case invalidURL

    /// Error for REST API requests with invalid cookie nonce
    case invalidCookieNonce

    /// The HTTP response code of the network error, for cases that are deducted from the status code.
    public var responseCode: Int? {
        switch self {
            case .notFound:
                return StatusCode.notFound
            case .timeout:
                return StatusCode.timeout
            case let .unacceptableStatusCode(statusCode, _):
                return statusCode
            default:
                return nil
        }
    }

    /// Response data accompanied the error if available
    var response: Data? {
        switch self {
        case .notFound(let response):
            return response
        case .timeout(let response):
            return response
        case .unacceptableStatusCode(_, let response):
            return response
        case .invalidURL, .invalidCookieNonce:
            return nil
        }
    }
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
            self = .notFound(response: responseData)
        case StatusCode.timeout:
            self = .timeout(response: responseData)
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
        case let .notFound(responseData):
            let response: String? = responseData.map { String(data: $0, encoding: .utf8) } ?? nil
            let format = NSLocalizedString(
                "NetworkError.notFound",
                value: "Sorry, we couldn't find what you were looking for. Please try again. Response: %1$@",
                comment: "Error message when we receive not found error")
            return String.localizedStringWithFormat(format, response ?? "")
        case let .timeout(responseData):
            let response: String? = responseData.map { String(data: $0, encoding: .utf8) } ?? nil
            let format = NSLocalizedString(
                "NetworkError.timeout",
                value: "Sorry, the request took too long to process. Please try again later. Response: %1$@",
                comment: "Error message when a request times out.")
            return String.localizedStringWithFormat(format, response ?? "")
        case let .unacceptableStatusCode(statusCode, responseData):
            let response: String? = responseData.map { String(data: $0, encoding: .utf8) } ?? nil
            let format = NSLocalizedString(
                "NetworkError.unacceptableStatusCode",
                value: "Sorry, there was an issue with the server. Please try again later. (Error code: %1$d). Response: %2$@",
                comment: "Error message when the a network call fails with unacceptable status code." +
                "%1$d is the status code like 500. %2$@ is the response string.")
            return String.localizedStringWithFormat(format, statusCode, response ?? "")
        case .invalidURL:
            return NSLocalizedString(
                "NetworkError.invalidURL",
                value: "Sorry, the URL is not valid. Please try again.",
                comment: "Error message when the URL is invalid.")
        case .invalidCookieNonce:
            return NSLocalizedString(
                "NetworkError.invalidCookieNonce",
                value: "Sorry, your session has expired. Please log in again.",
                comment: "Error message when session cookie has expired.")
        }
    }
}
