#if os(iOS)

import Foundation
import Codegen

/// Represents all of the possible Order Statuses in enum form
///
/// The order of the statuses declaration is according to the Order's lifecycle
/// and it is used to determine the user facing display order
///
public enum OrderStatusEnum: Codable, Hashable, Comparable, GeneratedFakeable {
    case autoDraft
    case pending
    case processing
    case onHold
    case completed
    case cancelled
    case refunded
    case failed
    case custom(String)
}

/// RawRepresentable Conformance
///
extension OrderStatusEnum: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.autoDraft:
            self = .autoDraft
        case Keys.pending:
            self = .pending
        case Keys.processing:
            self = .processing
        case Keys.onHold:
            self = .onHold
        case Keys.failed:
            self = .failed
        case Keys.cancelled:
            self = .cancelled
        case Keys.completed:
            self = .completed
        case Keys.refunded:
            self = .refunded
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value, also known as the `slug`
    ///
    public var rawValue: String {
        switch self {
        case .autoDraft:            return Keys.autoDraft
        case .pending:              return Keys.pending
        case .processing:           return Keys.processing
        case .onHold:               return Keys.onHold
        case .failed:               return Keys.failed
        case .cancelled:            return Keys.cancelled
        case .completed:            return Keys.completed
        case .refunded:             return Keys.refunded
        case .custom(let payload):  return payload
        }
    }
}


/// Enum containing the 'Known' OrderStatus Keys
///
private enum Keys {
    static let autoDraft    = "auto-draft"
    static let pending      = "pending"
    static let processing   = "processing"
    static let onHold       = "on-hold"
    static let failed       = "failed"
    static let cancelled    = "cancelled"
    static let completed    = "completed"
    static let refunded     = "refunded"
}

#endif
