import Foundation
import Codegen

/// Represents a ProductStatus Entity.
///
public enum ProductStatus: Codable, Hashable, GeneratedFakeable {
    case published
    case draft
    case pending
    case privateStatus  // `private` is a reserved keyword
    case autoDraft
    case importing      // used for placeholder products from a product import or template
    case custom(String) // in case there are extensions modifying product statuses
}


/// RawRepresentable Conformance
///
extension ProductStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.published:
            self = .published
        case Keys.draft:
            self = .draft
        case Keys.pending:
            self = .pending
        case Keys.privateStatus:
            self = .privateStatus
        case Keys.autoDraft:
            self = .autoDraft
        case Keys.importing:
            self = .importing
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .published:              return Keys.published
        case .draft:                return Keys.draft
        case .pending:              return Keys.pending
        case .privateStatus:        return Keys.privateStatus
        case .autoDraft:            return Keys.autoDraft
        case .importing:            return Keys.importing
        case .custom(let payload):  return payload
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .published:
            return NSLocalizedString("Published", comment: "Display label for the product's published status")
        case .draft:
            return NSLocalizedString("Draft", comment: "Display label for the product's draft status")
        case .pending:
            return NSLocalizedString("Pending review", comment: "Display label for the product's pending status")
        case .privateStatus:
            return NSLocalizedString("Privately published", comment: "Display label for the product's private status")
        case .autoDraft:
            return "Auto Draft" // We don't need to localize this now.
        case .importing:
            return "Importing" // We don't need to localize this now.
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}


/// Enum containing the 'Known' ProductType Keys
///
private enum Keys {
    static let published     = "publish"
    static let draft         = "draft"
    static let pending       = "pending"
    static let privateStatus = "private"
    static let autoDraft     = "auto-draft"
    static let importing     = "importing"
}
