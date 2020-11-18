import Foundation

/// The status of shipping label.
public enum ShippingLabelStatus {
    case purchased
}

/// RawRepresentable Conformance
extension ShippingLabelStatus: RawRepresentable {
    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.purchased:
            self = .purchased
        default:
            assertionFailure("Unexpected value for `ShippingLabelStatus`: \(rawValue)")
            self = .purchased
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .purchased:
            return Keys.purchased
        }
    }
}

/// Contains the supported ShippingLabelStatus values.
private enum Keys {
    static let purchased = "PURCHASED"
}
