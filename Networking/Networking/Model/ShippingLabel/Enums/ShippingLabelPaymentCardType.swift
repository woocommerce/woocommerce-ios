#if os(iOS)

import Foundation
import Codegen

/// The supported card types for Shipping Label Payment Methods.
///
public enum ShippingLabelPaymentCardType: String, Decodable, GeneratedFakeable {
    case amex
    case discover
    case mastercard
    case visa
    case paypal
}

#endif
