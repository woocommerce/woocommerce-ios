import Foundation

/// Represents a ProductBackordersSetting Entity.
///
public enum ProductBackordersSetting: Decodable, Hashable, GeneratedFakeable {
    case allowed
    case allowedAndNotifyCustomer
    case notAllowed
    case custom(String) // in case there are extensions modifying backorders setting
}

/// RawRepresentable Conformance
///
extension ProductBackordersSetting: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.allowed:
            self = .allowed
        case Keys.allowedAndNotifyCustomer:
            self = .allowedAndNotifyCustomer
        case Keys.notAllowed:
            self = .notAllowed
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .allowed: return Keys.allowed
        case .allowedAndNotifyCustomer: return Keys.allowedAndNotifyCustomer
        case .notAllowed: return Keys.notAllowed
        case .custom(let payload):  return payload
        }
    }
}

extension ProductBackordersSetting {
    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .allowed:
            return NSLocalizedString("Allow", comment: "Display label for the product's inventory backorders setting option")
        case .allowedAndNotifyCustomer:
            return NSLocalizedString("Allow, but notify customer", comment: "Display label for the product's inventory backorders setting option")
        case .notAllowed:
            return NSLocalizedString("Do not allow", comment: "Display label for the product's inventory backorders setting option")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}

/// Enum containing the 'Known' ProductBackordersSetting Keys
///
private enum Keys {
    static let allowed = "yes"
    static let allowedAndNotifyCustomer = "notify"
    static let notAllowed = "no"
}
