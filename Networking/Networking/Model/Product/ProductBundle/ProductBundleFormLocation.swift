import Foundation
import Codegen

/// Represents supported "Form Location" options for products with the bundle product type.
///
public enum ProductBundleFormLocation: Codable, Hashable, GeneratedFakeable {
    case defaultLocation
    case afterSummary
    case custom(String) // in case there are extensions modifying form location options
}


/// RawRepresentable Conformance
///
extension ProductBundleFormLocation: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.defaultLocation:
            self = .defaultLocation
        case Keys.afterSummary:
            self = .afterSummary
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .defaultLocation:        return Keys.defaultLocation
        case .afterSummary:              return Keys.afterSummary
        case .custom(let payload):  return payload
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .defaultLocation:
            return NSLocalizedString("Default", comment: "Display label for the product bundle's default form location")
        case .afterSummary:
            return NSLocalizedString("Before Tabs",
                                     comment: "Display label when a product bundle's add-to-cart form is displayed before the single-product tabs.")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}


/// Enum containing the 'Known' Product Bundle Form Location Keys
///
private enum Keys {
    static let defaultLocation  = "default"
    static let afterSummary     = "after_summary"
}
