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
