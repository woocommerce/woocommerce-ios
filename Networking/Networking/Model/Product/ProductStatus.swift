import Foundation


/// Represents a ProductStatus Entity.
///
public enum ProductStatus: Decodable, Hashable {
    case publish
    case draft
    case pending
    case privateStatus  // `private` is a reserved keyword
    case custom(String) // in case there are extensions modifying product statuses
}


/// RawRepresentable Conformance
///
extension ProductStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.publish:
            self = .publish
        case Keys.draft:
            self = .draft
        case Keys.pending:
            self = .pending
        case Keys.privateStatus:
            self = .privateStatus
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .publish:              return Keys.publish
        case .draft:                return Keys.draft
        case .pending:              return Keys.pending
        case .privateStatus:        return Keys.privateStatus
        case .custom(let payload):  return payload
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .publish:
            return NSLocalizedString("Published", comment: "Display label for the product's published status")
        case .draft:
            return NSLocalizedString("Draft", comment: "Display label for the product's draft status")
        case .pending:
            return NSLocalizedString("Pending review", comment: "Display label for the product's pending status")
        case .privateStatus:
            return NSLocalizedString("Private published", comment: "Display label for the product's private status")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}


/// Enum containing the 'Known' ProductType Keys
///
private enum Keys {
    static let publish       = "publish"
    static let draft         = "draft"
    static let pending       = "pending"
    static let privateStatus = "private"
}
