import Foundation


/// Represents a ProductStatus Entity.
///
public enum ProductStatus: Decodable, Hashable {
    case draft
    case pending
    case privateStatus
    case publish
    case custom(String) // in case there are extensions modifying product statuses
}


/// RawRepresentable Conformance
///
extension ProductStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.draft:
            self = .draft
        case Keys.pending:
            self = .pending
        case Keys.privateKey:
            self = .privateStatus
        case Keys.publish:
            self = .publish
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .draft:                return Keys.draft
        case .pending:              return Keys.pending
        case .privateStatus:        return Keys.privateKey
        case .publish:              return Keys.publish
        case .custom(let payload):  return payload
        }
    }
}


/// Enum containing the 'Known' ProductStatus Keys
///
private enum Keys {
    static let draft        = "draft"
    static let pending      = "pending"
    static let privateKey   = "private"
    static let publish      = "publish"
}
