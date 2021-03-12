import Foundation


/// Represents a ProductCatalogVisibility Entity.
///
public enum ProductCatalogVisibility: Decodable, Hashable, GeneratedFakeable {
    case visible
    case catalog
    case search
    case hidden
    case custom(String) // in case there are extensions modifying product catalog visibilities
}


/// RawRepresentable Conformance
///
extension ProductCatalogVisibility: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.visible:
            self = .visible
        case Keys.catalog:
            self = .catalog
        case Keys.search:
            self = .search
        case Keys.hidden:
            self = .hidden
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .visible:              return Keys.visible
        case .catalog:              return Keys.catalog
        case .search:               return Keys.search
        case .hidden:               return Keys.hidden
        case .custom(let payload):  return payload
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .visible:
            return NSLocalizedString("Shop and search results", comment: "Display label for the product's catalog visibility")
        case .catalog:
            return NSLocalizedString("Shop only", comment: "Display label for the product's catalog visibility")
        case .search:
            return NSLocalizedString("Search results only", comment: "Display label for the product's catalog visibility")
        case .hidden:
            return NSLocalizedString("Hidden", comment: "Display label for the product's catalog visibility")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}


/// Enum containing the 'Known' ProductType Keys
///
private enum Keys {
    static let visible = "visible"
    static let catalog = "catalog"
    static let search  = "search"
    static let hidden  = "hidden"
}
