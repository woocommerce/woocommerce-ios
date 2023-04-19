import Foundation

/// Represents all possible subscription statuses
///
public enum SubscriptionStatus: Codable, Equatable {
    case pending
    case active
    case onHold
    case expired
    case pendingCancel
    case cancelled
    case custom(String)
}

/// RawRepresentable Conformance
///
extension SubscriptionStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.pending:
            self = .pending
        case Keys.active:
            self = .active
        case Keys.onHold:
            self = .onHold
        case Keys.expired:
            self = .expired
        case Keys.pendingCancel:
            self = .pendingCancel
        case Keys.cancelled:
            self = .cancelled
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current enum case's raw value.
    ///
    public var rawValue: String {
        switch self {
        case .pending:              return Keys.pending
        case .active:               return Keys.active
        case .onHold:               return Keys.onHold
        case .expired:              return Keys.expired
        case .pendingCancel:        return Keys.pendingCancel
        case .cancelled:            return Keys.cancelled
        case .custom(let payload):  return payload
        }
    }
}


/// Enum containing the 'Known' SubscriptionStatus Keys
///
private enum Keys {
    static let pending       = "pending"
    static let active        = "active"
    static let onHold        = "on-hold"
    static let expired       = "expired"
    static let pendingCancel = "pending-cancel"
    static let cancelled     = "cancelled"
}
