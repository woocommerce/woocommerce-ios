import Foundation


/// Represents a ProductType Entity.
///
public enum ProductType: Decodable, Hashable {
    case simple
    case grouped
    case affiliate
    case variable
    case custom(String) // in case there are extensions modifying product types
}


/// RawRepresentable Conformance
///
extension ProductType: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.simple:
            self = .simple
        case Keys.grouped:
            self = .grouped
        case Keys.affiliate:
            self = .affiliate
        case Keys.variable:
            self = .variable
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .simple:               return Keys.simple
        case .grouped:              return Keys.grouped
        case .affiliate:            return Keys.affiliate
        case .variable:             return Keys.variable
        case .custom(let payload):  return payload
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .simple:
            return NSLocalizedString("Simple", comment: "Display label for simple product type.")
        case .grouped:
            return NSLocalizedString("Grouped", comment: "Display label for grouped product type.")
        case .affiliate:
            return NSLocalizedString("External/Affiliate", comment: "Display label for affiliate product type.")
        case .variable:
            return NSLocalizedString("Variable", comment: "Display label for variable product type.")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}


/// Enum containing the 'Known' ProductType Keys
///
private enum Keys {
    static let simple    = "simple"
    static let grouped   = "grouped"
    static let affiliate = "external"
    static let variable  = "variable"
}
