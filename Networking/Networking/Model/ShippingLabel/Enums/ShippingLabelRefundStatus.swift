import Foundation

/// The status of shipping label refund.
public enum ShippingLabelRefundStatus {
    case pending
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
            assertionFailure("Unexpected value for `ShippingLabelRefundStatus`: \(rawValue)")
            self = .pending
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .pending:
            return Keys.pending
        }
    }
}

/// Contains the supported ShippingLabelRefundStatus values.
private enum Keys {
    static let pending = "pending"
}
