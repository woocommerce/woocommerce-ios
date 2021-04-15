import Foundation

/// The supported card types for Shipping Label Payment Methods.
///
public enum ShippingLabelPaymentCardType: GeneratedFakeable {
    case amex
    case discover
    case mastercard
    case visa
    case paypal
}

/// RawRepresentable Conformance
extension ShippingLabelPaymentCardType: RawRepresentable {
    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.amex:
            self = .amex
        case Keys.discover:
            self = .discover
        case Keys.mastercard:
            self = .mastercard
        case Keys.visa:
            self = .visa
        case Keys.paypal:
            self = .paypal
        default:
            assertionFailure("Unexpected value for `ShippingLabelPaymentCardType`: \(rawValue)")
            self = .amex
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .amex:
            return Keys.amex
        case .discover:
            return Keys.discover
        case .mastercard:
            return Keys.mastercard
        case .visa:
            return Keys.visa
        case .paypal:
            return Keys.paypal
        }
    }
}

/// Contains the supported ShippingLabelPaymentCardType values.
private enum Keys {
    static let amex = "amex"
    static let discover = "discover"
    static let mastercard = "mastercard"
    static let visa = "visa"
    static let paypal = "paypal"
}
