import Foundation
import Codegen

/// Represents all supported layouts for products with the bundle product type.
///
public enum ProductBundleLayout: Codable, Hashable, GeneratedFakeable {
    case defaultLayout
    case tabular
    case grid
    case custom(String) // in case there are extensions modifying layout options
}


/// RawRepresentable Conformance
///
extension ProductBundleLayout: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.defaultLayout:
            self = .defaultLayout
        case Keys.tabular:
            self = .tabular
        case Keys.grid:
            self = .grid
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .defaultLayout:        return Keys.defaultLayout
        case .tabular:              return Keys.tabular
        case .grid:                 return Keys.grid
        case .custom(let payload):  return payload
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .defaultLayout:
            return NSLocalizedString("Standard", comment: "Display label for the product bundle's layout")
        case .tabular:
            return NSLocalizedString("Tabular", comment: "Display label for the product bundle's layout")
        case .grid:
            return NSLocalizedString("Grid", comment: "Display label for the product bundle's layout")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}


/// Enum containing the 'Known' Product Bundle Layout Keys
///
private enum Keys {
    static let defaultLayout    = "default"
    static let tabular          = "tabular"
    static let grid             = "grid"
}
