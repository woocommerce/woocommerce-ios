import Foundation


/// Represents a SiteSettingGroup Entity.
///
public enum SiteSettingGroup: Decodable, Hashable, GeneratedFakeable {
    case general
    case product
    case custom(String) // catch-all
}


/// RawRepresentable Conformance
///
extension SiteSettingGroup: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.general:
            self = .general
        case Keys.product:
            self = .product
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .general: return Keys.general
        case .product: return Keys.product
        case .custom(let payload):  return payload
        }
    }
}


/// Enum containing the SiteSettingGroup keys the app currently uses
///
private enum Keys {
    static let general = "general"
    static let product = "product"
}
