import Foundation

/// Represents a Customer.Role Entity.
///
extension Customer {
    public enum Role: Decodable, Hashable {
        case administrator
        case editor
        case author
        case contributor
        case subscriber
        case customer
        case shop_manager
        case custom(String) // catch-all
    }
}

/// RawRepresentable Conformance
///
extension Customer.Role: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.administrator:
            self = .administrator
        case Keys.editor:
            self = .editor
        case Keys.author:
            self = .author
        case Keys.contributor:
            self = .contributor
        case Keys.subscriber:
            self = .subscriber
        case Keys.customer:
            self = .customer
        case Keys.shop_manager:
            self = .shop_manager
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .administrator: return Keys.administrator
        case .editor: return Keys.editor
        case .author: return Keys.author
        case .contributor: return Keys.contributor
        case .subscriber: return Keys.subscriber
        case .customer: return Keys.customer
        case .shop_manager: return Keys.shop_manager
        case .custom(let payload): return payload
        }
    }
}

/// Enum containing the Customer.Role keys the app currently uses
///
private enum Keys {
    static let administrator = "administrator"
    static let editor        = "editor"
    static let author        = "author"
    static let contributor   = "contributor"
    static let subscriber    = "subscriber"
    static let customer      = "customer"
    static let shop_manager  = "shop_manager"
}
