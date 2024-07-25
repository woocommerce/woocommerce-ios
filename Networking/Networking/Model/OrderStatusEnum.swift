import Foundation
import Codegen

/// Represents all of the possible Order Statuses in enum form
///
/// The order of the statuses declaration is according to the Order's lifecycle
/// and it is used to determine the user facing display order
///
public enum OrderStatusEnum: Codable, Hashable, Comparable, Sendable, GeneratedFakeable {
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

public extension OrderStatusEnum {
    /// Returns the localized text version of the Enum
    ///
    var localizedName: String {
        switch self {
        case .autoDraft:
            return NSLocalizedString(
                "orderStatusEnum.localizedName.autoDraft",
                value: "Draft",
                comment: "Display label for auto-draft order status."
            )
        case .pending:
            return NSLocalizedString(
                "orderStatusEnum.localizedName.pending",
                value: "Pending Payment",
                comment: "Display label for pending order status."
            )
        case .processing:
            return NSLocalizedString(
                "orderStatusEnum.localizedName.processing",
                value: "Processing",
                comment: "Display label for processing order status."
            )
        case .onHold:
            return NSLocalizedString(
                "orderStatusEnum.localizedName.onHold",
                value: "On hold",
                comment: "Display label for on hold order status."
            )
        case .failed:
            return NSLocalizedString(
                "orderStatusEnum.localizedName.failed",
                value: "Failed",
                comment: "Display label for failed order status."
            )
        case .cancelled:
            return NSLocalizedString(
                "orderStatusEnum.localizedName.cancelled",
                value: "Cancelled",
                comment: "Display label for cancelled order status."
            )
        case .completed:
            return NSLocalizedString(
                "orderStatusEnum.localizedName.completed",
                value: "Completed",
                comment: "Display label for completed order status."
            )
        case .refunded:
            return NSLocalizedString(
                "orderStatusEnum.localizedName.refunded",
                value: "Refunded",
                comment: "Display label for refunded order status."
            )
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
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
