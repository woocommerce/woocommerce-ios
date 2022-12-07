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
    case unacceptableStatusCode(statusCode: Int)

    case invalidRequest

    case multipartEncodingFailed(reason: MultipartFormEncodingFailureReason)

    public enum MultipartFormEncodingFailureReason: Equatable {
        case outputStreamFileAlreadyExists(at: URL)
        case outputStreamURLInvalid(url: URL)
        case outputStreamCreationFailed(for: URL)
        case inputStreamReadFailed
        case outputStreamWriteFailed
        case bodyPartFilenameInvalid(in: URL)
        case bodyPartURLInvalid(url: URL)
        case bodyPartFileNotReachable(at: URL)
        case bodyPartFileNotReachableWithError(atURL: URL)
        case bodyPartFileIsDirectory(at: URL)
        case bodyPartFileSizeNotAvailable(at: URL)
        case bodyPartFileSizeQueryFailedWithError(forURL: URL)
        case bodyPartInputStreamCreationFailed(for: URL)
    }
}

// MARK: - Public Methods
//
extension NetworkError {

    /// Designated Initializer
    ///
    init?(from statusCode: Int) {
        guard StatusCode.success.contains(statusCode) == false else {
            return nil
        }

        switch statusCode {
        case StatusCode.notFound:
            self = .notFound
        case StatusCode.timeout:
            self = .timeout
        default:
            self = .unacceptableStatusCode(statusCode: statusCode)
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
