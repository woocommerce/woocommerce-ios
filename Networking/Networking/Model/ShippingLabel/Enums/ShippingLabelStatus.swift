import Foundation
import Codegen

/// The status of shipping label.
public enum ShippingLabelStatus: GeneratedFakeable {
    case purchased
    case purchaseError
    case purchaseInProgress
    case unknown
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
            DDLogError("⛔️ Unexpected value for `ShippingLabelStatus`: \(rawValue)")
            self = .unknown
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
        case .unknown:
            return ""
        }
    }
}

/// Contains the supported ShippingLabelStatus values.
private enum Keys {
    static let purchased = "PURCHASED"
    static let purchaseError = "PURCHASE_ERROR"
    static let purchaseInProgress = "PURCHASE_IN_PROGRESS"
}
