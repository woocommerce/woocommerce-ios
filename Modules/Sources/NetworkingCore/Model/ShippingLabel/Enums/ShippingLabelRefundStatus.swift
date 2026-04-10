import Foundation
import Codegen

/// The status of shipping label refund.
public enum ShippingLabelRefundStatus: Sendable, GeneratedFakeable {
    case pending
    case unknown
}

/// RawRepresentable Conformance
extension ShippingLabelRefundStatus: RawRepresentable {
    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.pending:
            self = .pending
        default:
            DDLogError("⛔️ Unexpected value for `ShippingLabelRefundStatus`: \(rawValue)")
            self = .unknown
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .pending:
            return Keys.pending
        case .unknown:
            return ""
        }
    }
}

/// Contains the supported ShippingLabelRefundStatus values.
private enum Keys {
    static let pending = "pending"
}
