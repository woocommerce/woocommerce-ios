import Foundation


/// Represents all of the possible Order Statuses
///
public enum OrderStatus: Decodable, Hashable {
    case pending
    case processing
    case onHold
    case failed
    case cancelled
    case completed
    case refunded
    case custom(String)
}


/// RawRepresentable Conformance
///
extension OrderStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
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

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
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


/// StringConvertible Conformance
///
extension OrderStatus: CustomStringConvertible {

    /// Returns a string describing the current OrderStatus Instance
    /// Custom doesn't return a localized string because the payload arrives at runtime, not buildtime.
    ///
    public var description: String {
        switch self {
        case .pending:              return NSLocalizedString("Pending", comment: "Pending Order Status")
        case .processing:           return NSLocalizedString("Processing", comment: "Processing Order Status")
        case .onHold:               return NSLocalizedString("On Hold", comment: "On Hold Order Status")
        case .failed:               return NSLocalizedString("Failed", comment: "Failed Order Status")
        case .cancelled:            return NSLocalizedString("Canceled", comment: "Cancelled Order Status")
        case .completed:            return NSLocalizedString("Completed", comment: "Completed Order Status")
        case .refunded:             return NSLocalizedString("Refunded", comment: "Refunded Order Status")
        case .custom(let payload):
            return payload
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }
    }
}


/// Enum containing the 'Known' OrderStatus Keys
///
private enum Keys {
    static let pending      = "pending"
    static let processing   = "processing"
    static let onHold       = "on-hold"
    static let failed       = "failed"
    static let cancelled    = "cancelled"
    static let completed    = "completed"
    static let refunded     = "refunded"
}
