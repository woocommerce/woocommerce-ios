import Foundation

/// Represents a OrderFeeTaxStatus Entity.
///

public enum OrderFeeTaxStatus: Decodable, Hashable, GeneratedFakeable {
    case taxable
    case none
}


/// RawRepresentable Conformance
///
extension OrderFeeTaxStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.taxable:
            self = .taxable
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
        case .none: return Keys.none
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .taxable:
            return NSLocalizedString("Taxable", comment: "Display label for the order fee's tax status setting option")
        case .none:
            return NSLocalizedString("None", comment: "Display label for the order fee's tax status setting option")
        }
    }
}


/// Enum containing the 'Known' OrderFeeTaxStatus Keys
///
private enum Keys {
    static let taxable  = "taxable"
    static let none     = "none"
}
