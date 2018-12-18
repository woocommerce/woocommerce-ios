import Foundation


/// WordPress.com Request Error
///
public enum DotcomError: Error, Decodable {

    /// Non explicit reason
    ///
    case empty

    /// We're not properly authenticated
    ///
    case invalidToken

    /// Remote Request Failed
    ///
    case requestFailed

    /// Unknown: Represents an unmapped remote error. Capisce?
    ///
    case unknown(code: String, message: String?)



    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let error = try container.decode(String.self, forKey: .error)

        switch error {
        case Constants.requestFailed:
            self = .requestFailed
        case Constants.invalidToken:
            self = .invalidToken
        default:
            let message = try container.decodeIfPresent(String.self, forKey: .message)
            self = .unknown(code: error, message: message)
        }
    }


    /// Constants
    ///
    private enum Constants {
        static let invalidToken     = "invalid_token"
        static let requestFailed    = "http_request_failed"
    }

    /// Coding Keys
    ///
    private enum CodingKeys: String, CodingKey {
        case error
        case message
    }
}


// MARK: - Equatable Conformance
//
public func ==(lhs: DotcomError, rhs: DotcomError) -> Bool {
    switch (lhs, rhs) {
    case (.requestFailed, .requestFailed):
        return true
    case let (.unknown(codeLHS, _), .unknown(codeRHS, _)):
        return codeLHS == codeRHS
    default:
        return false
    }
}
