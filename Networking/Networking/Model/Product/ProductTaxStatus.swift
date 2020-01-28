import Foundation

/// Represents a ProductTaxStatus Entity.
///
public enum ProductTaxStatus: Decodable, Hashable {
    case taxable
    case shipping
    case none
}


/// RawRepresentable Conformance
///
extension ProductTaxStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.taxable:
            self = .taxable
        case Keys.shipping:
            self = .shipping
        case Keys.none:
            self = .none
        default:
            self = .taxable
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .taxable: return Keys.taxable
        case .shipping: return Keys.shipping
        case .none: return Keys.none
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .taxable:
            return NSLocalizedString("Taxable", comment: "Display label for the product's tax status setting option")
        case .shipping:
            return NSLocalizedString("Shipping only", comment: "Display label for the product's tax status setting option")
        case .none:
            return NSLocalizedString("None", comment: "Display label for the product's tax status setting option")
        }
    }
}


/// Enum containing the 'Known' ProductTaxStatus Keys
///
private enum Keys {
    static let taxable  = "taxable"
    static let shipping = "shipping"
    static let none     = "none"
}
