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

/// MARK: - DotcomError Methods
///
extension DotcomError {

    /// Designated Initializer
    ///
    init?(dictionary: [AnyHashable: Any]) {
        guard let code = dictionary[CodingKeys.code.rawValue] as? String else {
            return nil
        }

        self.code = code
        self.message = dictionary[CodingKeys.message.rawValue] as? String
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
