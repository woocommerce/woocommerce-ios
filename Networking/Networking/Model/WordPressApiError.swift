import Foundation

/// WordPress API Request Error
///
public enum WordPressApiError: Error, Decodable, Equatable {

    /// Unknown: Represents an unmapped remote error.
    ///
    case unknown(code: String, message: String)

    /// An order already exists for this IAP receipt
    ///
    case productPurchased

    /// Decodable Initializer.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let code = try container.decode(String.self, forKey: .code)
        let message = try container.decode(String.self, forKey: .message)

        switch code {
        case Constants.productPurchased:
            self = .productPurchased
        default:
            self = .unknown(code: code, message: message)
        }
    }


    /// Constants for Possible Error Identifiers
    ///
    private enum Constants {
        static let productPurchased = "product_purchased"
    }

    /// Coding Keys
    ///
    private enum CodingKeys: String, CodingKey {
        case code
        case message
    }

    /// Possible Error Messages
    ///
    private enum ErrorMessages {
        static let statsModuleDisabled = "This blog does not have the Stats module enabled"
        static let noStatsPermission = "user cannot view stats"
        static let resourceDoesNotExist = "Resource does not exist."
    }
}


// MARK: - CustomStringConvertible Conformance
//
extension WordPressApiError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .productPurchased:
            return NSLocalizedString(
                "An order aready exists for this receipt",
                comment: "Error message when an order already exists in the backend for a given receipt")
        case .unknown(let code, let message):
            let messageFormat = NSLocalizedString(
                "WordPress API Error: [%1$@] %2$@",
                comment: "WordPress API (unmapped!) error. Parameters: %1$@ - code, %2$@ - message"
            )
            return String.localizedStringWithFormat(messageFormat, code, message)
        }
    }
}

// MARK: - LocalizedError Conformance
//
extension WordPressApiError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}
