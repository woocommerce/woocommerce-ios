import Foundation
import Codegen

/// Represents supported item grouping options for products with the bundle product type.
///
public enum ProductBundleItemGrouping: Codable, Hashable, GeneratedFakeable {
    case parent
    case noindent
    case none
    case custom(String) // in case there are extensions modifying item grouping options
}


/// RawRepresentable Conformance
///
extension ProductBundleItemGrouping: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.parent:
            self = .parent
        case Keys.noindent:
            self = .noindent
        case Keys.none:
            self = .none
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .parent:        return Keys.parent
        case .noindent:              return Keys.noindent
        case .none:              return Keys.none
        case .custom(let payload):  return payload
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .parent:
            return NSLocalizedString("Grouped", comment: "Display label for the product bundle's item grouping")
        case .noindent:
            return NSLocalizedString("Flat", comment: "Display label for the product bundle's item grouping")
        case .none:
            return NSLocalizedString("None", comment: "Display label for the product bundle's item grouping")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}


/// Enum containing the 'Known' Product Bundle Form Location Keys
///
private enum Keys {
    static let parent   = "parent"
    static let noindent = "noindent"
    static let none     = "none"
}
