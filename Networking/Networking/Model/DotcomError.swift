import Foundation


/// WordPress.com Request Error
///
public struct DotcomError: Error, Decodable {

    /// Error Code
    ///
    public let error: String

    /// Descriptive Message
    ///
    public let message: String?
}


/// Known Dotcom Errors
///
public extension DotcomError {

    /// Request Failure
    ///
    public static var requestFailed: DotcomError {
        return DotcomError(error: "http_request_failed", message: nil)
    }

    /// Something went wrong. We just don't know what!
    ///
    public static var unknown: DotcomError {
        return DotcomError(error: "unknown", message: nil)
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: DotcomError, rhs: DotcomError) -> Bool {
    return lhs.error == rhs.error
}
