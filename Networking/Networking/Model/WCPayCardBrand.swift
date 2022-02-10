import Foundation
import Codegen

/// Model for card brands as returned from WCPay.
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card-brand)
///
public enum WCPayCardBrand: String, Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case amex
    case diners
    case discover
    case jcb
    case mastercard
    case unionpay
    case visa
    case unknown

    /// A displayable brand name for the card.
    /// Names taken from [Stripe's card branding in the API docs](https://stripe.com/docs/api/cards/object#card_object-brand):
    /// American Express, Diners Club, Discover, JCB, MasterCard, UnionPay, Visa, or Unknown.
    public func localizedBrand() -> String {
        switch self {
        case .amex:
            return NSLocalizedString("American Express", comment: "American Express card brand name")
        case .diners:
            return NSLocalizedString("Diners Club", comment: "Diners Club card brand name")
        case .discover:
            return NSLocalizedString("Discover", comment: "Discover card brand name")
        case .jcb:
            return NSLocalizedString("JCB", comment: "JCB card brand name")
        case .mastercard:
            return NSLocalizedString("MasterCard", comment: "MasterCard card brand name")
        case .unionpay:
            return NSLocalizedString("UnionPay", comment: "UnionPay card brand name")
        case .visa:
            return NSLocalizedString("Visa", comment: "Visa card brand name")
        case .unknown:
            return NSLocalizedString("Unknown", comment: "Short string to describe an unknown card brand, used" +
                                     "in contexts where otherwise the card network would be displayed, e.g." +
                                     "\"Visa\" or \"MasterCard\"")
        }
    }
}
