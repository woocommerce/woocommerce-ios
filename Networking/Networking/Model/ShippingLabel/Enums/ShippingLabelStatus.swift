import Foundation
import Codegen

/// The status of shipping label.
public enum ShippingLabelStatus: GeneratedFakeable {
    case purchased
    case purchaseError
    case purchaseInProgress
}

/// RawRepresentable Conformance
extension ShippingLabelStatus: RawRepresentable {
    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.purchased:
            self = .purchased
        case Keys.purchaseInProgress:
            self = .purchaseInProgress
        case Keys.purchaseError:
            self = .purchaseError
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
        case .purchaseInProgress:
            return Keys.purchaseInProgress
        case .purchaseError:
            return Keys.purchaseError
        }
    }
}

/// Contains the supported ShippingLabelStatus values.
private enum Keys {
    static let purchased = "PURCHASED"
    static let purchaseError = "PURCHASE_ERROR"
    static let purchaseInProgress = "PURCHASE_IN_PROGRESS"
}
