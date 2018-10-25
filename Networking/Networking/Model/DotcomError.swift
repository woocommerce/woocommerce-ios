import Foundation


/// WordPress.com Request Error
///
public struct DotcomError: Error, Decodable {

    /// Error Code
    ///
    public let code: String

    /// Descriptive Message
    ///
    public let message: String?


    /// Coding Keys!
    ///
    private enum CodingKeys: String, CodingKey {
        case code = "error"
        case message
    }
}


/// Known Dotcom Errors
///
extension DotcomError {

    /// Something went wrong. We just don't know what!
    ///
    static var unknown: DotcomError {
        return DotcomError(code: "unknown", message: nil)
    }
}
