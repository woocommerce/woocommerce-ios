import Foundation


/// Represents a ProductType Entity.
///
public enum ProductType: Decodable, Hashable {
    case simple
    case grouped
    case external
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
        case Keys.external:
            self = .external
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
        case .external:             return Keys.external
        case .variable:             return Keys.variable
        case .custom(let payload):  return payload
        }
    }
}


/// Enum containing the 'Known' ProductType Keys
///
private enum Keys {
    static let simple   = "simple"
    static let grouped  = "grouped"
    static let external = "external"
    static let variable = "variable"
}
